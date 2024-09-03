import os
import json
import argparse

class EnvironmentConfigurator():
    
    def __init__(self,config_file_path, map_file_path, map_file_iptables_path, services_home):
        
        self.config_file_path = config_file_path
        self.map_file_path = map_file_path
        self.map_file_iptables_path = map_file_iptables_path
        self.services_home = services_home
        
        self.config_vars = self.load_config_from_file()
        self.replace_map = self.load_replace_map(self.map_file_path)
        self.replace_map_iptables = self.load_replace_map(self.map_file_iptables_path) if map_file_iptables_path else None
    
    def _is_comment(self,line):
        return line.startswith('##')
    
    def load_replace_map(self, map_path):
        with open(map_path) as f:
            replace_map = json.load(f)
        return replace_map
    
    def load_config_from_file(self):
        config_vars = {}
        with open(self.config_file_path, 'r') as config_file:
            for line in config_file:
                line = line.strip()
                if line and not self._is_comment(line):
                    if line.startswith((
                        "MAC_ADDRESSES_TO_BLOCK",
                        "TAILSCALE_IP_RANGE",
                        "LOCAL_NETWORK_IP_RANGE"
                    )):
                        key, value = line.split('=', 1)
                        values = value.strip().split(',')
                        config_vars[key] = values
                    else:
                        key, value = line.split('=', 1)
                        config_vars[key] = value

        return config_vars
    
    def map_env_vars(self):
        for env_file in self.replace_map:
            env_file_path = env_file["path"].replace("$SERVICES_HOME", self.services_home)

            with open(env_file_path) as f:
                env_file_contents = f.read()
                for placeholder, config_variable in env_file["replace"].items():
                    env_file_contents = env_file_contents.replace(placeholder,self.config_vars.get(config_variable,''))

            with open(env_file_path,"w") as f:
                f.write(env_file_contents)
                
    def map_env_vars_iptables(self):
        
        set_ip_tables = []
        revert_ip_tables = []
        
        for entry in self.replace_map_iptables:
            for placeholder, config_variable in entry["replace"].items():
                entry["replace"][placeholder] = self.config_vars.get(config_variable,'')
        
        for entry in self.replace_map_iptables:
            path = entry["path"].replace("$SERVICES_HOME", self.services_home)

            if path.endswith("set_ip_tables.sh"):

                set_ip_tables.extend(entry["prefix"])
                ips_to_allow = entry["replace"]["<TAILSCALE_IP_RANGE>"] + entry["replace"]["<LOCAL_NETWORK_IP_RANGE>"]
                for ip in ips_to_allow:
                    if ip != '':
                        set_ip_tables.append(entry["accept"].replace("<IP_RANGE>",ip))

                mac_addresses_to_block = entry["replace"]["<MAC_ADDRESSES_TO_BLOCK>"]

                for address in mac_addresses_to_block:
                    if address != '':
                        set_ip_tables.append(entry["drop"].replace("<MAC_ADDRESSES_TO_BLOCK>",address))
                        set_ip_tables.append(entry["drop_input"].replace("<MAC_ADDRESSES_TO_BLOCK>",address))

                with open(path,"w") as f:
                    f.write("\n".join(set_ip_tables))

            if path.endswith("revert_ip_tables.sh"):
                revert_ip_tables.extend(entry["prefix"])
                mac_addresses_to_block = entry["replace"]["<MAC_ADDRESSES_TO_BLOCK>"]

                for address in mac_addresses_to_block:
                    if address != '':
                        revert_ip_tables.append(entry["drop"].replace("<MAC_ADDRESSES_TO_BLOCK>",address))

                with open(path,"w") as f:
                    f.write("\n".join(revert_ip_tables))

if __name__== "__main__":
    
    parser = argparse.ArgumentParser(description='Sets Environment Vars for .env files')
    parser.add_argument('--process_iptables', action='store_true', help='Whether to process IPTABLES')
    args = parser.parse_args()
        
    services_home = os.getenv("SERVICES_HOME")
        
    config_path = f"{services_home}/utils/config.conf"
    map_file_path = f"{services_home}/utils/map.json"
    map_file_iptables_path = f"{services_home}/utils/map_iptables.json" if args.process_iptables else None
        
    configurator = EnvironmentConfigurator(config_file_path=config_path,
                                          map_file_path=map_file_path,
                                          map_file_iptables_path=map_file_iptables_path,
                                          services_home = services_home)
    configurator.map_env_vars()
    if args.process_iptables:
        configurator.map_env_vars_iptables()