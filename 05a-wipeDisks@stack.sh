#!/bin/bash
NewTemplates=/home/stack/new_templates
sed -i '/.*add new block here.*/i\ \ \ \ \ \ - config: {get_resource: deploy-WipeDisk}' $NewTemplates/firstboot.yaml

cat << EOF  >>  $NewTemplates/firstboot.yaml

  deploy-WipeDisk:
    type: OS::Heat::SoftwareConfig
    properties:
      config: |
        #!/bin/bash
        case "\$(hostname)" in
          *ceph*)
            for i in {b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s}; do
              if [ -b /dev/sd\${i} ]; then
                echo "(II) Wiping disk /dev/sd\${i}..."
                dd if=/dev/zero of=/dev/sd\${i} bs=1M count=512
                sgdisk -Z /dev/sd\${i}
                sgdisk -o /dev/sd\${i}
              fi
            done
          ;;
          *control*)
            i="b"
                echo "(II) Wiping disk /dev/sd\${i}..."
                dd if=/dev/zero of=/dev/sd\${i} bs=1M count=512
                sgdisk -Z /dev/sd\${i}
                sgdisk -o /dev/sd\${i}
                sgdisk -N 1 /dev/sd\${i}
                partprobe /dev/sd\${i}
                mkfs.xfs -L "SWIFT-DATA" /dev/sd\${i}1
                echo "/dev/sd\${i}1	/srv	xfs	defaults	1	1">>/etc/fstab
                mount /srv
          ;;
        esac

EOF


