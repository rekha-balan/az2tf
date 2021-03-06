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
#
#
vnets=`az network vnet list -g $rgsource`
count=`echo $vnets | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for j in `seq 0 $count`; do
        vname=`echo $vnets | jq ".[(${j})].name" | tr -d '"'`
        #
        azr=`az network vnet subnet list -g $rgsource --vnet-name $vname`
        scount=`echo $azr | jq '. | length'`
        scount=`expr $scount - 1`
        for i in `seq 0 $scount`; do
            name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
            rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
            id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`
            # subnets don't have a location
            prefix=`printf "%s__%s" $prefixa $rg`
            outfile=`printf "%s.%s__%s.tf" $tfp $rg $name`
            echo $az2tfmess > $outfile

            sprefix=`echo $azr | jq ".[(${i})].addressPrefix" | tr -d '"'`
            
            seps=`echo $azr | jq ".[(${i})].serviceEndpoints"`
            sep1=`echo $azr | jq ".[(${i})].serviceEndpoints[0].service"`
            sep2=`echo $azr | jq ".[(${i})].serviceEndpoints[1].service"`
            sep="null"
            rtbid="null"
            if [ "$sep1" != "null" ]; then
                sep=`printf "[%s]" $sep1`
            fi
            if [ "$sep2" != "null" ]; then
                sep=`printf "[%s,%s]" $sep1 $sep2`
            fi
            
            snsg=`echo $azr | jq ".[(${i})].networkSecurityGroup.id" | cut -f9 -d"/" | tr -d '"'`
            snsgrg=`echo $azr | jq ".[(${i})].networkSecurityGroup.id" | cut -f5 -d"/" | tr -d '"'`
            
            printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name >> $outfile
            printf "\t name = \"%s\"\n" $name >> $outfile
            
            printf "\t virtual_network_name = \"%s\"\n" $vname >> $outfile
            printf "\t address_prefix = \"%s\"\n" $sprefix >> $outfile
            rtbid=`echo $azr | jq ".[(${i})].routeTable.id" | cut -f9 -d"/" | tr -d '"'`
            rtrg=`echo $azr | jq ".[(${i})].routeTable.id" | cut -f5 -d"/" | tr -d '"'`
            #printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $outfile
            printf "\t resource_group_name = \"%s\"\n" $rg >> $outfile
            if [ "$snsg" != "null" ]; then
                printf "\t network_security_group_id = \"\${azurerm_network_security_group.%s__%s.id}\"\n" $snsgrg $snsg >> $outfile
            fi
            if [ "$sep" != "null" ]; then
                printf "\t service_endpoints = %s\n" $sep >> $outfile
            fi
            if [ "$rtbid" != "null" ]; then
                printf "\t route_table_id = \"\${azurerm_route_table.%s__%s.id}\"\n" $rtrg $rtbid >> $outfile
            fi

            printf "}\n" >> $outfile
            cat $outfile
            statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
            echo $statecomm >> tf-staterm.sh
            eval $statecomm
            evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
            echo $evalcomm >> tf-stateimp.sh
            eval $evalcomm
        done
    done
fi
