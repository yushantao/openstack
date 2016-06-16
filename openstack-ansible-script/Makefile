unsafe: unsafe-network.yml
	ansible-playbook -i "$(PWD)/clusters/$(CLUSTER)" -u root -k -e "target=$(TARGET)" $< $(EXTRA)
%: %.yml
	ansible-playbook -i "$(PWD)/clusters/$(CLUSTER)" -u root -k -e "target=$(CLUSTER):$@" $< $(EXTRA)
%-single: %.yml
	ansible-playbook -i "$(PWD)/clusters/$(CLUSTER)" -u root -k -e "target=$(TARGET)" $< $(EXTRA)
