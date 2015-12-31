#!/bin/bash
# MSM8X26 L release kernel build script v0.3
# nc.chaudhary@samsung.com
# aapav01@gmail.com <Customized>

BUILD_TOP_DIR=..
BUILD_KERNEL_DIR=$(pwd)

BUILD_CROSS_COMPILE=~/working/kernel/arm-eabi-4.8/bin/arm-eabi-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`

KERNEL_DEFCONFIG=msm8226-sec_defconfig
SELINUX_DEFCONFIG=selinux_defconfig

shift $((OPTIND-1))

BUILD_COMMAND=$1

MODEL=${BUILD_COMMAND%%_*}
TEMP=${BUILD_COMMAND#*_}
REGION=${TEMP%%_*}
CARRIER=${TEMP##*_}

echo "######### PARAMETERS ##########"
echo "MODEL   = $MODEL"
echo "TEMP    = $TEMP"
echo "REGION  = $REGION"
echo "CARRIER = $CARRIER"
echo "######### END  #########"

if [[ "$BUILD_COMMAND" == "ms01lte"* ]]; then		# MS01_LTE
	VARIANT=${MODEL}_${CARRIER}
	DTS_NAMES=msm8926-sec-ms01lteeur-r
elif [[ "$BUILD_COMMAND" == "ms013g"* ]]; then		# MS01_3g
	VARIANT=${MODEL}_${CARRIER}
	DTS_NAMES=msm8226-sec-ms013geur-r
elif [[ "$BUILD_COMMAND" == "s3ve3g"* ]]; then		# S3ve_3g
	VARIANT=${MODEL}_${CARRIER}
	DTS_NAMES=msm8226-sec-s3ve3geur-r
elif [[ "$BUILD_COMMAND" == "milletlte_vzw"* ]]; then
	VARIANT=${MODEL}_${CARRIER}
DTS_NAMES=msm8926-sec-milletltevzw-r
#DTS_NAMES=msm8926-sec-milletlte_tmo-r
elif [[ "$BUILD_COMMAND" == "NewModel"* ]]; then	# New Model
	VARIANT=NewModel${CARRIER}
	DTS_NAMES=NewModel-DTS-NAME
else
	DTS_NAMES=
fi

PROJECT_NAME=${VARIANT}
if [ "$MODEL" == "ms01lte" ]; then
	VARIANT_DEFCONFIG=msm8926-sec_${MODEL}_${CARRIER}_defconfig
elif [ "$MODEL" == "milletlte" ]; then
	VARIANT_DEFCONFIG=msm8926-sec_${MODEL}_${CARRIER}_defconfig
else
	VARIANT_DEFCONFIG=msm8226-sec_${MODEL}_${CARRIER}_defconfig
fi

case $1 in
		clean)
		echo "Clean..."
		#make -C $BUILD_KERNEL_DIR clean
		#make -C $BUILD_KERNEL_DIR distclean
		BUILD_KERNEL_OUT_DIR=$BUILD_TOP_DIR/okernel/*$2
		echo "remove kernel out directory $BUILD_KERNEL_OUT_DIR"
		rm $BUILD_KERNEL_OUT_DIR -rf
		exit 1
		;;

		*)
		BUILD_KERNEL_OUT_DIR=$BUILD_TOP_DIR/okernel/$BUILD_COMMAND
		PRODUCT_OUT=$BUILD_TOP_DIR/okernel/$BUILD_COMMAND
		mkdir -p $BUILD_KERNEL_OUT_DIR
		;;

esac

KERNEL_ZIMG=$BUILD_KERNEL_OUT_DIR/arch/arm/boot/zImage
DTC=$BUILD_KERNEL_OUT_DIR/scripts/dtc/dtc

FUNC_APPEND_DTB()
{
	if ! [ -d $BUILD_KERNEL_OUT_DIR/arch/arm/boot ] ; then
		echo "error no directory : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot""
		exit -1
	else
		echo "rm files in : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot/*-zImage""
		rm $BUILD_KERNEL_OUT_DIR/arch/arm/boot/*-zImage
		echo "rm files in : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot/*.dtb""
		rm $BUILD_KERNEL_OUT_DIR/arch/arm/boot/*.dtb
	fi

	for DTS_FILE in `ls ${BUILD_KERNEL_DIR}/arch/arm/boot/dts/msm8226/${DTS_NAMES}*.dts`
	do
		DTB_FILE=${DTS_FILE%.dts}.dtb
		DTB_FILE=$BUILD_KERNEL_OUT_DIR/arch/arm/boot/${DTB_FILE##*/}
		ZIMG_FILE=${DTB_FILE%.dtb}-zImage

		echo ""
		echo "dts : $DTS_FILE"
		echo "dtb : $DTB_FILE"
		echo "out : $ZIMG_FILE"
		echo ""

		$DTC -p 1024 -O dtb -o $DTB_FILE $DTS_FILE
		cat $KERNEL_ZIMG $DTB_FILE > $ZIMG_FILE
	done
}

INSTALLED_DTIMAGE_TARGET=${BUILD_KERNEL_OUT_DIR}/dt.img
DTBTOOL=$BUILD_TOP_DIR/samsung_${MODEL}_${CARRIER}/tools/dtbTool

FUNC_BUILD_DTIMAGE_TARGET()
{
	echo ""
	echo "================================="
	echo "START : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
	echo "DT image target : $INSTALLED_DTIMAGE_TARGET"

	if ! [ -e $DTBTOOL ] ; then
		if ! [ -d $BUILD_TOP_DIR/out/host/linux-x86/bin ] ; then
			mkdir -p $BUILD_TOP_DIR/out/host/linux-x86/bin
		fi
		cp $BUILD_TOP_DIR/kernel/tools/dtbTool $DTBTOOL
	fi

	BOARD_KERNEL_PAGESIZE=2048

	echo "$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p $BUILD_KERNEL_OUT_DIR/scripts/dtc/ $BUILD_KERNEL_OUT_DIR/arch/arm/boot/"
		$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p $BUILD_KERNEL_OUT_DIR/scripts/dtc/ $BUILD_KERNEL_OUT_DIR/arch/arm/boot/

	chmod a+r $INSTALLED_DTIMAGE_TARGET

	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
}

FUNC_BUILD_KERNEL()
{
	echo ""
	echo "=============================================="
	echo "START : FUNC_BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "build project="$PROJECT_NAME""
	echo "build common config="$KERNEL_DEFCONFIG ""
	echo "build variant config="$VARIANT_DEFCONFIG ""
	echo "build secure option="$SECURE_OPTION ""
	echo "build SEANDROID option="$SEANDROID_OPTION ""

	if [ "$BUILD_COMMAND" == "" ]; then
		SECFUNC_PRINT_HELP;
		exit -1;
	fi

	if [ "$TEMP" == "$MODEL" ]; then
		KERNEL_DEFCONFIG=msm8226-sec_${MODEL}_defconfig
		make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm \
				CROSS_COMPILE=$BUILD_CROSS_COMPILE \
				$KERNEL_DEFCONFIG \
				DEBUG_DEFCONFIG=$DEBUG_DEFCONFIG SELINUX_DEFCONFIG=$SELINUX_DEFCONFIG \
				SELINUX_LOG_DEFCONFIG=$SELINUX_LOG_DEFCONFIG || exit -1
	else
		make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm \
				CROSS_COMPILE=$BUILD_CROSS_COMPILE \
				$KERNEL_DEFCONFIG VARIANT_DEFCONFIG=$VARIANT_DEFCONFIG \
				DEBUG_DEFCONFIG=$DEBUG_DEFCONFIG SELINUX_DEFCONFIG=$SELINUX_DEFCONFIG \
				SELINUX_LOG_DEFCONFIG=$SELINUX_LOG_DEFCONFIG || exit -1
	fi

	make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1

	#FUNC_APPEND_DTB
	FUNC_BUILD_DTIMAGE_TARGET
	
	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}


FUNC_EXT_MODULES_TARGET()
{

	echo ""
	echo "===================================="
	echo "  START : FUNC_EXT_MODULES_TARGET"
	echo "===================================="
	echo ""

	OUT_MODU=$BUILD_TOP_DIR/mkernel/$BUILD_COMMAND
	rm -rf $OUT_MODU
	mkdir -p $OUT_MODU
	find $BUILD_KERNEL_OUT_DIR -name "*.ko" -exec cp -fv {} $OUT_MODU \;

	echo ""
	echo "===================================="
	echo "  END : FUNC_EXT_MODULES_TARGET"
	echo "===================================="
	echo ""

}

SECFUNC_PRINT_HELP()
{
	echo -e '\E[33m'
	echo "Help"
	echo "$0 \$1 \$2"
	echo "  \$1 : "
	echo "      ms013g"
	echo "      s3ve3g"
	echo "      s3ve3g_eur"
	echo "      ms013g_eur"
	echo "      ms01lte_eur"
	echo "      milletlte_vzw"
	echo "  \$2 : <only when \$1 is clean>"
	echo "      ms013g"
	echo "      s3ve3g"
	echo "      s3ve3g_eur"
	echo "      ms013g_eur"
	echo "      ms01lte_eur"
	echo "      milletlte_vzw"
	echo -e '\E[0m'
}


# MAIN FUNCTION
rm -rf ./build.log
(
	START_TIME=`date +%s`

	FUNC_BUILD_KERNEL
	FUNC_EXT_MODULES_TARGET

	cp -vf $KERNEL_ZIMG $BUILD_KERNEL_OUT_DIR

	END_TIME=`date +%s`

	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./build.log
