prefixa=`echo $0 | awk -F 'azurerm_' '{print $2}' | awk -F '.sh' '{print $1}' `
tfp=`printf "azurerm_%s" $prefixa`
if [ "$1" != "" ]; then
    rgsource=$1
else
    echo -n "Enter name of Resource Group [$rgsource] > "
    read response
    if [ -n "$response" ]; then
        rgsource=$response
    fi
fi
azr=`az network application-gateway list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
        loc=`echo $azr | jq ".[(${i})].location"`
        skun=`echo $azr | jq ".[(${i})].sku.name" | tr -d '"'`
        skuc=`echo $azr | jq ".[(${i})].sku.capacity" | tr -d '"'`
        skut=`echo $azr | jq ".[(${i})].sku.tier" | tr -d '"'`
        
        
        # the blocks
        gwipc=`echo $azr | jq ".[(${i})].gatewayIpConfigurations"`
        feps=`echo $azr | jq ".[(${i})].frontendPorts"`
        fronts=`echo $azr | jq ".[(${i})].frontendIpConfigurations"`
        beap=`echo $azr | jq ".[(${i})].backendAddressPools"`
        bhttps=`echo $azr | jq ".[(${i})].backendHttpSettingsCollection"`
        httpl=`echo $azr | jq ".[(${i})].httpListeners"`
        probes=`echo $azr | jq ".[(${i})].probes"`
        rrrs=`echo $azr | jq ".[(${i})].requestRoutingRules"`
        urlpm=`echo $azr | jq ".[(${i})].urlPathMaps"`
        authcerts=`echo $azr | jq ".[(${i})].authenticationCertificates"`
        sslcerts=`echo $azr | jq ".[(${i})].sslCertificates"`
        wafc=`echo $azr | jq ".[(${i})].webApplicationFirewallConfiguration"`
        
        prefix=`printf "%s.%s" $prefixa $rg`
        outfile=`printf "%s.%s__%s.tf" $tfp $rg $name`
        echo $az2tfmess > $outfile  
        
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $outfile
        printf "\t name = \"%s\"\n" $name >> $outfile
        printf "\t location = %s\n" "$loc" >> $outfile
        printf "\t resource_group_name = \"%s\"\n" $rg >> $outfile
        printf "sku {\n" $sku >> $outfile
        printf "\t name = \"%s\"\n" $skun >> $outfile
        printf "\t capacity = \"%s\"\n" $skuc >> $outfile
        printf "\t tier = \"%s\"\n" $skut >> $outfile
        printf "}\n" $sku >> $outfile
        
        # gateway ip config block
        
        icount=`echo $gwipc | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                gname=`echo $azr | jq ".[(${i})].gatewayIpConfigurations[(${j})].name" | tr -d '"'`
                subrg=`echo $azr | jq ".[(${i})].gatewayIpConfigurations[(${j})].subnet.id" | cut -d'/' -f5 | tr -d '"'`
                subname=`echo $azr | jq ".[(${i})].gatewayIpConfigurations[(${j})].subnet.id" | cut -d'/' -f11 | tr -d '"'`
                printf "gateway_ip_configuration {\n" >> $outfile
                printf "\t name = \"%s\" \n"  $gname >> $outfile
                if [ "$subname" != "null" ]; then
                    printf "\t subnet_id = \"\${azurerm_subnet.%s__%s.id}\"\n" $subrg $subname >> $outfile
                fi
                printf "}\n" >> $outfile
            done
        fi
        
        # front end port
        icount=`echo $feps | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                fname=`echo $azr | jq ".[(${i})].frontendPorts[(${j})].name" | tr -d '"'`
                fport=`echo $azr | jq ".[(${i})].frontendPorts[(${j})].port" | tr -d '"'`
                printf "frontend_port {\n" >> $outfile
                printf "\t name = \"%s\" \n"  $fname >> $outfile
                printf "\t port = \"%s\" \n"  $fport >> $outfile
                printf "}\n" >> $outfile
            done
        fi
        
        # front end ip config block
        icount=`echo $fronts | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                
                fname=`echo $azr | jq ".[(${i})].frontendIpConfigurations[(${j})].name" | tr -d '"'`
                priv=`echo $azr | jq ".[(${i})].frontendIpConfigurations[(${j})].privateIpAddress" | tr -d '"'`
                
                pubrg=`echo $azr | jq ".[(${i})].frontendIpConfigurations[(${j})].publicIpAddress.id" | cut -d'/' -f5 | tr -d '"'`
                pubname=`echo $azr | jq ".[(${i})].frontendIpConfigurations[(${j})].publicIpAddress.id" | cut -d'/' -f9 | tr -d '"'`
                
                subrg=`echo $azr | jq ".[(${i})].frontendIpConfigurations[(${j})].subnet.id" | cut -d'/' -f5 | tr -d '"'`
                subname=`echo $azr | jq ".[(${i})].frontendIpConfigurations[(${j})].subnet.id" | cut -d'/' -f11 | tr -d '"'`
                privalloc=`echo $azr | jq ".[(${i})].frontendIpConfigurations[(${j})].privateIpAllocationMethod" | tr -d '"'`
                
                printf "frontend_ip_configuration {\n" >> $outfile
                printf "\t name = \"%s\" \n"  $fname >> $outfile
                if [ "$subname" != "null" ]; then
                    printf "\t subnet_id = \"\${azurerm_subnet.%s__%s.id}\"\n" $subrg $subname >> $outfile
                fi
                if [ "$priv" != "null" ]; then
                    printf "\t private_ip_address = \"%s\" \n"  $priv >> $outfile
                fi
                if [ "$privalloc" != "null" ]; then
                    printf "\t private_ip_address_allocation  = \"%s\" \n"  $privalloc >> $outfile
                fi
                if [ "$pubname" != "null" ]; then
                    printf "\t public_ip_address_id = \"\${azurerm_public_ip.%s__%s.id}\"\n" $pubrg $pubname >> $outfile
                fi
                
                printf "}\n" >> $outfile
                
            done
        fi
        
        icount=`echo $beap | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                bname=`echo $azr | jq ".[(${i})].backendAddressPools[(${j})].name" | tr -d '"'`
                printf "backend_address_pool {\n" >> $outfile
                printf "\t name = \"%s\" \n"  $bname >> $outfile
                printf "}\n" >> $outfile
            done
        fi

        icount=`echo $bhttps | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                bname=`echo $azr | jq ".[(${i})].backendHttpSettingsCollection[(${j})].name" | tr -d '"'`
                bport=`echo $azr | jq ".[(${i})].backendHttpSettingsCollection[(${j})].port" | tr -d '"'`
                bproto=`echo $azr | jq ".[(${i})].backendHttpSettingsCollection[(${j})].protocol" | tr -d '"'`
                bcook=`echo $azr | jq ".[(${i})].backendHttpSettingsCollection[(${j})].cookieBasedAffinity" | tr -d '"'`
                btimo=`echo $azr | jq ".[(${i})].backendHttpSettingsCollection[(${j})].requestTimeout" | tr -d '"'`
                pname=`echo $azr | jq ".[(${i})].backendHttpSettingsCollection[(${j})].probe.id" | cut -d'/' -f11 | tr -d '"'`

                printf "backend_http_settings {\n" >> $outfile
                printf "\t name = \"%s\" \n"  $bname >> $outfile
                printf "\t port = \"%s\" \n"  $bport >> $outfile
                printf "\t protocol = \"%s\" \n"  $bproto >> $outfile
                printf "\t cookie_based_affinity = \"%s\" \n"  $bcook >> $outfile
                printf "\t request_timeout = \"%s\" \n"  $btimo >> $outfile
                printf "\t probe_name = \"%s\" \n"  $pname >> $outfile

                printf "}\n" >> $outfile
            done
        fi     
        
# http listener block          httpl=`echo $azr | jq ".[(${i})].httpListeners"`


        icount=`echo $httpl | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                bname=`echo $azr | jq ".[(${i})].httpListeners[(${j})].name" | tr -d '"'`
                feipcn=`echo $azr | jq ".[(${i})].httpListeners[(${j})].frontendIpConfiguration.id" | cut -d'/' -f11 | tr -d '"'`
                fepn=`echo $azr | jq ".[(${i})].httpListeners[(${j})].frontendPort.id" | cut -d'/' -f11 | tr -d '"'`  
                bproto=`echo $azr | jq ".[(${i})].httpListeners[(${j})].protocol" | tr -d '"'`
                bhn=`echo $azr | jq ".[(${i})].httpListeners[(${j})].hostName" | tr -d '"'`
                bssl=`echo $azr | jq ".[(${i})].httpListeners[(${j})].sslCertificate" | tr -d '"'`
                                

                printf "http_listener {\n" >> $outfile
                printf "\t name = \"%s\" \n"  $bname >> $outfile
                printf "\t frontend_ip_configuration_name = \"%s\" \n"  $feipcn >> $outfile
                printf "\t frontend_port_name = \"%s\" \n"  $fepn >> $outfile
                printf "\t protocol = \"%s\" \n"  $bproto >> $outfile
                if [ "$bhn" != "null" ]; then
                printf "\t host_name = \"%s\" \n"  $bhn >> $outfile
                fi
                if [ "$bssl" != "null" ]; then
                printf "\t ssl_certificate_name = \"%s\" \n"  $bssl >> $outfile
                fi
                #printf "\t require_sni = \"%s\" \n"  $rsni >> $outfile

                printf "}\n" >> $outfile
            done
        fi   

# proble block  probes=`echo $azr | jq ".[(${i})].probes"`

        icount=`echo $probes | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                bname=`echo $azr | jq ".[(${i})].probes[(${j})].name" | tr -d '"'`
                bproto=`echo $azr | jq ".[(${i})].probes[(${j})].protocol" | tr -d '"'`
                bpath=`echo $azr | jq ".[(${i})].probes[(${j})].path" | tr -d '"'`
                bhost=`echo $azr | jq ".[(${i})].probes[(${j})].host" | tr -d '"'`
                bint=`echo $azr | jq ".[(${i})].probes[(${j})].interval" | tr -d '"'`
                btimo=`echo $azr | jq ".[(${i})].probes[(${j})].timeout" | tr -d '"'`
                bunth=`echo $azr | jq ".[(${i})].probes[(${j})].unhealthyThreshold" | tr -d '"'`
                bmsrv=`echo $azr | jq ".[(${i})].probes[(${j})].minServers" | tr -d '"'`               
                bmbod=`echo $azr | jq ".[(${i})].probes[(${j})].match.body" | tr -d '"'`             
                bmstat=`echo $azr | jq ".[(${i})].probes[(${j})].match.statusCodes"` 

                printf "probe{\n" >> $outfile
                printf "\t name = \"%s\" \n"  $bname >> $outfile
                printf "\t protocol = \"%s\" \n"  $bproto >> $outfile
                printf "\t path = \"%s\" \n"  $bpath >> $outfile
                printf "\t host = \"%s\" \n"  $bhost >> $outfile
                printf "\t interval = \"%s\" \n"  $bint >> $outfile
                printf "\t timeout = \"%s\" \n"  $btimo >> $outfile
                printf "\t unhealthy_threshold = \"%s\" \n"  $bunth >> $outfile


                if [ "$bmsrv" != "null" ]; then
                printf "\t minimum_servers = \"%s\" \n"  $bmsrv >> $outfile
                fi

                printf "\t match {\n" >> $outfile
                if [ "$bmbod" != "null" ]; then
                    if [ "$bmbod" = "" ]; then
                        printf "\t\t body = \"*\" \n" >> $outfile
                    else
                        printf "\t\t body = \"%s\" \n"  $bmbod >> $outfile
                    fi
                fi
                printf "\t }\n" >> $outfile
                
                #if [ "$bmstat" != "null" ]; then
                #printf "\t status_code = \"%s\" \n"  $bmstat >> $outfile
                #fi
                

                printf "}\n" >> $outfile
            done
        fi   

# request routing rules block rrrs=`echo $azr | jq ".[(${i})].requestRoutingRules"`

        icount=`echo $probes | jq '. | length'`
        if [ "$icount" -gt "0" ]; then
            icount=`expr $icount - 1`
            for j in `seq 0 $icount`; do
                bname=`echo $azr | jq ".[(${i})].requestRoutingRules[(${j})].name" | tr -d '"'`
                btyp=`echo $azr | jq ".[(${i})].requestRoutingRules[(${j})].ruleType" | tr -d '"'`
                blin=`echo $azr | jq ".[(${i})].requestRoutingRules[(${j})].httpListener.id" | cut -d'/' -f11 | tr -d '"'`
                bapn=`echo $azr | jq ".[(${i})].requestRoutingRules[(${j})].backendAddressPool.id" | cut -d'/' -f11 | tr -d '"'`
                bhsn=`echo $azr | jq ".[(${i})].requestRoutingRules[(${j})].backendHttpSettings.id" | cut -d'/' -f11 | tr -d '"'`

                printf "request_routing_rule {\n" >> $outfile

                printf "\t name = \"%s\" \n"  $bname >> $outfile
                printf "\t rule_type = \"%s\" \n"  $btyp >> $outfile
                printf "\t http_listener_name = \"%s\" \n"  $blin >> $outfile
                if [ "$bapn" != "null" ]; then
                    printf "\t backend_address_pool_name = \"%s\" \n"  $bapn >> $outfile
                fi
                if [ "$bhsn" != "null" ]; then
                    printf "\t backend_http_settings_name = \"%s\" \n"  $bhsn >> $outfile
                fi
                printf "\t }\n" >> $outfile
            done
        fi


# waf configuration block     wafc=`echo $azr | jq ".[(${i})].webApplicationFirewallConfiguration"`
# - not an array like the other blocks 
#

        if [ "wafc" != "null" ]; then
            
                fmode=`echo $azr | jq ".[(${i})].webApplicationFirewallConfiguration.firewallMode" | tr -d '"'`
                rst=`echo $azr | jq ".[(${i})].webApplicationFirewallConfiguration.ruleSetType" | tr -d '"'`
                rsv=`echo $azr | jq ".[(${i})].webApplicationFirewallConfiguration.ruleSetVersion" | tr -d '"'`
                fen=`echo $azr | jq ".[(${i})].webApplicationFirewallConfiguration.enabled" | tr -d '"'`

                printf "waf_configuration {\n" >> $outfile

                printf "\t firewall_mode = \"%s\" \n"  $fmode >> $outfile
                printf "\t rule_set_type = \"%s\" \n"  $rst >> $outfile
                printf "\t rule_set_version = \"%s\" \n"  $rsv >> $outfile
                printf "\t enabled = \"%s\" \n"  $fen >> $outfile
                printf "\t }\n" >> $outfile
            
        fi


        #
        # New Tags block
        tags=`echo $azr | jq ".[(${i})].tags"`
        tt=`echo $tags | jq .`
        tcount=`echo $tags | jq '. | length'`
        if [ "$tcount" -gt "0" ]; then
            printf "\t tags { \n" >> $outfile
            tt=`echo $tags | jq .`
            keys=`echo $tags | jq 'keys'`
            tcount=`expr $tcount - 1`
            for j in `seq 0 $tcount`; do
                k1=`echo $keys | jq ".[(${j})]"`
                tval=`echo $tt | jq .$k1`
                tkey=`echo $k1 | tr -d '"'`
                printf "\t\t%s = %s \n" $tkey "$tval" >> $outfile
            done
            printf "\t}\n" >> $outfile
        fi
        
        
        printf "}\n" >> $outfile
        #
        echo $prefix
        echo $prefix__$name
        cat $outfile
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        echo $statecomm >> tf-staterm.sh
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        echo $evalcomm >> tf-stateimp.sh
        eval $evalcomm
    done
fi
