openstack 搭建指南
先决条件

路由器准备阶段



物理机准备阶段
0 同步时间服务器 关闭iptables 以正确的姿势配置网卡 初始化时epel源开启
  git clone https://github.com/yushantao/openstack/blob/master/openstack-patch/ansible-1.9.4-1.el6.noarch.rpm
1 ansible-server端 为ansible-1.9.4 版本  （2.0版本keystone模块发生变化）
2 双网卡 双VLAN A网段为管理网段   B网段为虚拟机网段(路由器dhcp功能关闭) 网关设置为A的 要求能ping通外网（repo下载） 设置主机名为l-optest.ops.bj0
3 ansible-server 能和client通讯
4 ansible cluster 文件的配置 在
5 python-six ftp://fr2.rpmfind.net/linux/centos/6.8/os/i386/Packages/python-six-1.9.0-2.el6.noarch.rpm

>>>>        sudoers 文件问题
>>>>        确认nova 和cinder都是在sudoers里  并且nova用户为可以登录权限

安装阶段
控制节点
6 在ansible-server 执行 make controller CLUSTER=test
计算节点（TARGET为cluster/test里hostname）
make compute-single CLUSTER=test TARGET=10.36.99.3
7 控制节点执行命令
source /etc/keystone/keystonerc
nova network-create vlan798 —bridge br798 --multi-host T --fixed-range-v4 10.36.98.0/24
8 导入img文件  在img文件当前目录运行 python -m SimpleHTTPServer 19000
9 导入完成后在云主机类型中选择适合于镜像的方式（因为镜像中有指定磁盘大小如果设置不对会报错）
  nova boot --flavor std --image centos --availability-zone nova:l-optest.ops.bj0 l-test.ops.bj0
10  关于如何制作镜像问题在openstack官网查询或者达令wiki   http://wiki.corp.daling.com/index.php?title=Openstack_%E9%95%9C%E5%83%8F%E5%88%B6%E4%BD%9C
    关于vnc不通的问题 新版openstackvnc有bug 索性用以前版本的源码去替换文件
    git clone https://github.com/yushantao/openstack/tree/master/openstack-file-patch
    rm -rf /usr/lib/python2.6/site-packages/websockify/
    cp openstack-file-patch/* /usr/lib/python2.6/site-packages/websockify/
    /etc/init.d/openstack-nova-novncproxy restart
