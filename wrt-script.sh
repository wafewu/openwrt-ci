# 修改默认IP & 固件名称
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate
sed -i "s/hostname='.*'/hostname='OpenWRT'/g" package/base-files/files/bin/config_generate
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ Build by waffe')/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js


# 修改亚瑟运行LED为绿色
# sed -i 's/&status_blue/\&status_green/g' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6000-re-ss-01.dts

# 修改太乙启动LED为绿色，运行LED为蓝色(VIKINGYFY项目)
# sed -i 's/boot/roc/g; s/running/boot/g; s/roc/running/g' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6010-re-cs-07.dts


#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#预置OpenClash内核和数据
if [ -d *"openclash"* ]; then
	CORE_VER="https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/core_version"
	CORE_TYPE=$(echo $WRT_TARGET | grep -Eiq "64|86" && echo "amd64" || echo "arm64")
	CORE_TUN_VER=$(curl -sL $CORE_VER | sed -n "2{s/\r$//;p;q}")

	CORE_DEV="https://github.com/vernesong/OpenClash/raw/core/dev/dev/clash-linux-$CORE_TYPE.tar.gz"
	CORE_MATE="https://github.com/vernesong/OpenClash/raw/core/dev/meta/clash-linux-$CORE_TYPE.tar.gz"
	CORE_TUN="https://github.com/vernesong/OpenClash/raw/core/dev/premium/clash-linux-$CORE_TYPE-$CORE_TUN_VER.gz"

	GEO_MMDB="https://github.com/alecthw/mmdb_china_ip_list/raw/release/lite/Country.mmdb"
	GEO_SITE="https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat"
	GEO_IP="https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat"

	cd ./luci-app-openclash/root/etc/openclash/

	curl -sL -o Country.mmdb $GEO_MMDB && echo "Country.mmdb done!"
	curl -sL -o GeoSite.dat $GEO_SITE && echo "GeoSite.dat done!"
	curl -sL -o GeoIP.dat $GEO_IP && echo "GeoIP.dat done!"

	mkdir ./core/ && cd ./core/

	curl -sL -o meta.tar.gz $CORE_MATE && tar -zxf meta.tar.gz && mv -f clash clash_meta && echo "meta done!"
	curl -sL -o tun.gz $CORE_TUN && gzip -d tun.gz && mv -f tun clash_tun && echo "tun done!"
	curl -sL -o dev.tar.gz $CORE_DEV && tar -zxf dev.tar.gz && echo "dev done!"

	chmod +x ./* && rm -rf ./*.gz

	cd $PKG_PATH && echo "openclash date has been updated!"
fi

# 移除要替换的包
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/packages/net/ariang
rm -rf package/emortal/luci-app-athena-led
rm -rf feeds/packages/lang/golang

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# Alist & AdGuardHome & WolPlus & AriaNg & 集客无线AC控制器 & Lucky & 雅典娜LED控制 & Go
#git_sparse_clone main https://github.com/wafewu/Packages adguardhome luci-app-adguardhome
git_sparse_clone main https://github.com/kenzok8/small-package adguardhome luci-app-adguardhome
#git clone --depth=1 https://github.com/sirpdboy/luci-app-advancedplus package/luci-app-advancedplus
#git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki package/nikki
git_sparse_clone master https://github.com/immortalwrt/packages net/ariang
git clone --depth=1 https://github.com/lwb1978/openwrt-gecoosac package/openwrt-gecoosac
#git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky
git clone --depth=1 --single-branch --branch main https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git_sparse_clone main https://github.com/wafewu/Packages luci-app-wolplus
#git_sparse_clone master https://github.com/tty228/luci-app-wechatpush package/luci-app-wechatpush
git_sparse_clone main https://github.com/asvow/luci-app-tailscale package/luci-app-tailscale
git clone --depth=1 https://github.com/lisaac/luci-app-diskman  package/luci-app-diskman

rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

#git_sparse_clone master https://github.com/kenzok8/small luci-app-ssr-plus shadowsocks-rust shadowsocksr-libev

# Themes
#git clone --depth=1 https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat
#git clone --depth=1  https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon

# 更改 Argon 主题背景
#cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# msd_lite
#git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
#git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite


# SmartDNS
git clone --depth=1 https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# MosDNS
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/v2ray-geodata

git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复Coremark编译失败
CM_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/coremark/Makefile")
if [ -f "$CM_FILE" ]; then
	sed -i 's/mkdir/mkdir -p/g' $CM_FILE

	cd $PKG_PATH && echo "coremark has been fixed!"
fi

# 修复 hostapd 报错
cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

update_golang() {
    if [[ -d ./feeds/packages/lang/golang ]]; then
        \rm -rf ./feeds/packages/lang/golang
        git clone $GOLANG_REPO -b $GOLANG_BRANCH ./feeds/packages/lang/golang
    fi
}

 #修复vlmcsd编译失败
vlmcsd_dir="$GITHUB_WORKSPACE/wrt/feeds/packages/net/vlmcsd"
vlmcsd_patch_src="$GITHUB_WORKSPACE/scripts/fix_compile_with_ccache.patch"
vlmcsd_patch_dest="$vlmcsd_dir/patches"

if [ -d "$vlmcsd_dir" ]; then
	# 检查补丁文件是否存在
	if [ ! -f "$vlmcsd_patch_src" ]; then
		echo "Error: vlmcsd patch file $vlmcsd_patch_src not found!" >&2
		exit 1
	fi

	# 创建目标目录并复制补丁
	mkdir -p "$vlmcsd_patch_dest" || exit 1
	cp -f "$vlmcsd_patch_src" "$vlmcsd_patch_dest" || exit 1

	# 进入源码目录应用补丁（如果未应用过）
	if ! grep -q 'fix_compile_with_ccache' "$vlmcsd_dir/Makefile" 2>/dev/null; then
		cd "$vlmcsd_dir" || exit 1
		patch -p1 < "$vlmcsd_patch_src" && echo "vlmcsd: Patch applied to source!" || echo "vlmcsd: Patch may already be applied."
		cd "$PKG_PATH"
	fi

	echo "vlmcsd: Patch copied and applied successfully!"
	cd "$PKG_PATH" && echo "vlmcsd has been fixed!"
else
	echo "Warning: vlmcsd directory $vlmcsd_dir not found, skipping patch."
fi


#修复DiskMan编译失败
DM_FILE="./luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
	echo " "

	sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE

	cd $PKG_PATH && echo "diskman has been fixed!"
fi

#修复rpcsvc-proto编译失败
RP_PATH="../feeds/packages/libs/rpcsvc-proto"
if [ -d "$RP_PATH" ]; then
	echo " "

	cd $RP_PATH && mkdir -p patches && cd ./patches

	curl -sL -o "0001-po-update-for-gettext-0.22.patch" https://raw.githubusercontent.com/neheb/packages/refs/heads/mangix/libs/rpcsvc-proto/patches/0001-po-update-for-gettext-0.22.patch

	cd $PKG_PATH && echo "rpcsvc-proto has been fixed!"
fi

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

sed -i ':a;N;s/msgid "Wake on LAN +"\s*msgstr ""/msgid "Wake on LAN +"\nmsgstr "网络唤醒+"/g;ta' $(find ./package/luci-app-wolplus/po/zh_Hans/wolplus.po)

./scripts/feeds update -a
./scripts/feeds install -a
