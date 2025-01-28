import paramiko
import requests
import os
from datetime import datetime

WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")
SSH_USER = os.getenv("SSH_USER", "default_user")
SERVERS = {
    "server_1_ip": {"name": "Home-Serv", "services": ["plexmediaserver", "agentdvr", "smb", "pivpn"], "key_path": os.getenv("HOME_SERV_SSH_KEY_PATH")},
    "server_2_ip": {"name": "Piraph", "services": ["nginx", "openvpn@server"], "key_path": os.getenv("PIRAPH_SSH_KEY_PATH")},
    "server_3_ip": {"name": "Second", "services": [], "key_path": os.getenv("SECOND_SERVER_SSH_KEY_PATH")},
}

def send_message_to_discord(message):
    payload = {"content": "@everyone " + message}
    try:
        response = requests.post(WEBHOOK_URL, json=payload)
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Erreur lors de l'envoi du message : {e}")

def execute_command(ssh_client, command):
    try:
        stdin, stdout, stderr = ssh_client.exec_command(command)
        return stdout.read().decode().strip()
    except Exception as e:
        return f"Erreur: {e}"

def check_local_services():
    results = {}
    results["CPU Temp"] = os.popen("vcgencmd measure_temp").read().strip().replace("temp=","").replace("'C", "°C")
    results["RAM Usage"] = os.popen("free -h | grep Mem | awk '{print $3 \" / \" $2}'").read().strip()
    cpu_usage = os.popen("top -d 1 -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\\1/' | awk '{print 100 - $1}'").read().strip()
    if not cpu_usage or cpu_usage == "0":
        cpu_usage = "0%"
    results["CPU Usage"] = cpu_usage
    disk_usage = os.popen("df -h | grep '/dev/mmcblk0p2' | awk '{print $3 \" / \" $2}'").read().strip()
    results["Disk Usage"] = disk_usage
    vpn_clients = os.popen("sudo netstat -tnpa | grep 'ESTABLISHED.*openvpn' | wc -l").read().strip()
    results["VPN Status"] = os.popen("systemctl is-active openvpn@server").read().strip()
    results["VPN Clients"] = vpn_clients
    results["GPU Temp"] = os.popen("vcgencmd measure_temp").read().strip().replace("temp=","").replace("'C", "°C")
    return results

def check_remote_server(ssh_client, server_name, server_ip):
    results = {}
    if server_name == "Home-Serv":
        disk_usage = execute_command(ssh_client, "df -h /mnt/md127 | awk 'NR==2 {print $3 \" / \" $2}'")
        plex_status = execute_command(ssh_client, "systemctl is-active plexmediaserver")
        agentdvr_status = execute_command(ssh_client, 'sudo docker ps --filter "name=AgentDVR-Server"')
        samba_status = execute_command(ssh_client, "systemctl is-active smb")
        cpu_usage = execute_command(ssh_client, "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\\1/' | awk '{print 100 - $1}'")
        ram_usage = execute_command(ssh_client, "free -h | grep Mem | awk '{print $3 \" / \" $2}'")
        cpu_temp = execute_command(ssh_client, "cat /sys/class/thermal/thermal_zone0/temp")
        gpu_temp = execute_command(ssh_client, "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null")
        if not gpu_temp:
            gpu_temp = execute_command(ssh_client, "vcgencmd measure_temp")
        results["Disk Usage"] = disk_usage
        results["Plex"] = plex_status
        results["Agent DVR"] = agentdvr_status if agentdvr_status else "inactive"
        results["Samba"] = samba_status
        results["CPU Temp"] = f"{int(cpu_temp) / 1000}°C"
        results["GPU Temp"] = gpu_temp if gpu_temp else "N/A"
        results["CPU Usage"] = f"{cpu_usage}%"
        results["RAM Usage"] = ram_usage
    elif server_name == "Second":
        disk_usage = execute_command(ssh_client, "df -h | grep '/dev/mmcblk0p2' | awk '{print $3 \" / \" $2}'")
        cpu_usage = execute_command(ssh_client, "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\\1/' | awk '{print 100 - $1}'")
        ram_usage = execute_command(ssh_client, "free -h | grep Mem | awk '{print $3 \" / \" $2}'")
        cpu_temp = execute_command(ssh_client, "cat /sys/class/thermal/thermal_zone0/temp")
        gpu_temp = execute_command(ssh_client, "vcgencmd measure_temp").replace("temp=", "").replace("'C", "°C")
        results["Disk Usage"] = disk_usage
        results["CPU Temp"] = f"{int(cpu_temp) / 1000}°C"
        results["GPU Temp"] = gpu_temp
        results["CPU Usage"] = f"{cpu_usage}%"
        results["RAM Usage"] = ram_usage
    return results

def generate_table(results_by_server):
    metrics = ["CPU Temp", "GPU Temp", "CPU Usage", "RAM Usage", "Disk Usage", "Plex", "Agent DVR", "Samba", "VPN Status", "VPN Clients"]
    headers = ["Metric"] + [server for server in results_by_server.keys()]
    rows = {metric: [] for metric in metrics}
    for server, metrics_dict in results_by_server.items():
        for metric in metrics:
            rows[metric].append(metrics_dict.get(metric, "N/A"))
    table = [" | ".join(headers), " | ".join(["-" * len(header) for header in headers])]
    for metric, values in rows.items():
        row = [metric] + values
        table.append(" | ".join(row))
    return "\n".join(table)

def main():
    results_by_server = {}
    results_by_server["Piraph"] = check_local_services()
    for ip, config in SERVERS.items():
        if config["name"] == "Piraph":
            continue
        try:
            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh_client.connect(ip, username=SSH_USER, key_filename=config["key_path"], timeout=30)
            results_by_server[config["name"]] = check_remote_server(ssh_client, config["name"], ip)
            ssh_client.close()
        except Exception as e:
            results_by_server[config["name"]] = {"Error": f"Failed to connect: {e}"}
    table = generate_table(results_by_server)
    send_message_to_discord(f"```\n{table}\n```")

if __name__ == "__main__":
    main()
