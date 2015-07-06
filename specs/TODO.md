Supporting tools.

- Image builder
   - Import from docker images / Registry
- Image maintainace 
   - Can runc images utilize Docker Registry to store | docker dist?


Issues:
- Should not force to change server OS.
- Proxy should be set at one place, and should reflect everywhere in echosystem.
- Containers as service. 
   - Traditionaly, servers run services in VM and dedicated baremetal machines.
   - To migrate them ( without rewritting the application logic of services), containers should target to provide alternative to VMs for services, so it can be migrated with least changes.
   - Also, if containers are child process of one single process, securty concerns are there.
      - Strongly consider, SELinux is disabled in 80-90% Traditional servers. Admins hate them.
   - container engine should support both application container and system container.

- Reverse proxy migration from IP based lookup (VIP)
- Networking support - Multihost
- Storage support for diffrent backends.
- Central Log collection and filtering.
- Central Montioring dashboard (mutihost can be viewed)
- 
   
