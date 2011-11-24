#!/bin/bash -xe

# NOTES:
# - eds builds against system libical not the locally built one
# - ensure that system libical version matches LIBICAL_VERSION below

LIBICAL_VERSION="0.44"
EDS_VERSION="3.2.1"

# --- do not modify below ---

APP_NAME="$(basename $0 | sed 's#.bash##g')"
APP_DIR="$(dirname $PWD/$0)"
VAPI_DIR="${APP_DIR}/../vapi" # where .metadata is stored and where to copy final .vapi
LOG="${APP_DIR}/${APP_NAME}.log"

BASE_DIR="$(mktemp -d)"
SRC_DIR="${BASE_DIR}/src"
BUILD_DIR="${BASE_DIR}/build"
BUILD_DIR_LIBICAL="${BASE_DIR}/build.clean"
PKG_DIR="${BASE_DIR}/packages"
OUTPUT_DIR="${BASE_DIR}/output"

LIBICAL_SRC_DIR="${SRC_DIR}/libical-${LIBICAL_VERSION}"
LIBICAL_SRC_URL="https://launchpad.net/ubuntu/+archive/primary/+files/libical_${LIBICAL_VERSION}.orig.tar.gz"

EDS_SRC_DIR="${SRC_DIR}/evolution-data-server-${EDS_VERSION}"
EDS_SRC_URL="https://launchpad.net/ubuntu/+archive/primary/+files/evolution-data-server_${EDS_VERSION}.orig.tar.bz2"

#LIBICAL_PACKAGES="libical libicalss libicalvcal"
LIBICAL_PACKAGES="libical"
ECALENDAR_PACKAGE="libecalendar-1.2"
EDATASERVER_PACKAGE="libedataserver-1.2"

get_archives()
{
    mkdir -p ${SRC_DIR}
    wget -P ${SRC_DIR} ${LIBICAL_SRC_URL} >> $LOG 2>&1
    wget -P ${SRC_DIR} ${EDS_SRC_URL} >> $LOG 2>&1
}

unpack_archives()
{
    rm -rf ${LIBICAL_SRC_DIR}
    LIBICAL_ARCHIVE="${SRC_DIR}/$(basename ${LIBICAL_SRC_URL})"
    tar -xzf ${LIBICAL_ARCHIVE} -C ${SRC_DIR}

    rm -rf ${EDS_SRC_DIR}
    EDS_ARCHIVE="${SRC_DIR}/$(basename ${EDS_SRC_URL})"
    tar -xjf ${EDS_ARCHIVE} -C ${SRC_DIR}
}

patch_libical()
{
    cd "${LIBICAL_SRC_DIR}/src"

    sed -i 's#${INCLUDE_BUILD_DIR_LIBICAL}/libical#${INCLUDE_BUILD_DIR_LIBICAL}/libicalss#g' libicalss/CMakeLists.txt
    sed -i 's#${INCLUDE_BUILD_DIR_LIBICAL}/libical#${INCLUDE_BUILD_DIR_LIBICAL}/libicalvcal#g' libicalvcal/CMakeLists.txt
}

clean_build_dir()
{
    rm -rf ${BUILD_DIR}
}

build_libical()
{
    cd ${LIBICAL_SRC_DIR}
    cmake -DCMAKE_INSTALL_PREFIX=${BUILD_DIR} -Wno-dev >> $LOG 2>&1
    make install >> $LOG 2>&1
}

build_eds()
{
    cd ${EDS_SRC_DIR}
    #CFLAGS=-I${BUILD_DIR}/include LDFLAGS=-L${BUILD_DIR}/lib ./configure \
    ./configure \
        --prefix=${BUILD_DIR} \
        --enable-vala-bindings \
        --enable-introspection=yes \
        >> $LOG 2>&1
    make install >> $LOG 2>&1
}

clean_install_dir()
{
    rm -rf ${BUILD_DIR_LIBICAL}
}

copy_gi_deps()
{
    mkdir -p ${BUILD_DIR_LIBICAL}/include/libical
    cp "${BUILD_DIR}/include/libical/ical.h" "${BUILD_DIR_LIBICAL}/include/libical"
    #mkdir -p ${BUILD_DIR_LIBICAL}/include/libicalss
    #cp "${BUILD_DIR}/include/libicalss/icalss.h" "${BUILD_DIR_LIBICAL}/include/libicalss"
    #cp -r "${BUILD_DIR}/include/libicalvcal" "${BUILD_DIR_LIBICAL}/include/libicalvcal"
    mkdir -p ${BUILD_DIR_LIBICAL}/lib
    cp ${BUILD_DIR}/lib/*.a "${BUILD_DIR_LIBICAL}/lib"
}

add_libical_typedefs()
{
    STRUCTS_LIBICAL="icaldurationtype \
        icalattachtype \
        icaldatetimeperiodtype \
        icalgeotype \
        icalperiodtype \
        icalproperty_impl \
        icalrecurrencetype \
        icalreqstattype \
        icaltimezonephase \
        icaltimezonetype \
        icaltriggertype \
        sspm_action_map \
        sspm_encoding \
        sspm_error \
        sspm_header \
        sspm_major_type \
        sspm_minor_type \
        sspm_part"
    for STRUCT in $STRUCTS_LIBICAL; do 
        echo "typedef struct $STRUCT $STRUCT;" >> ${BUILD_DIR_LIBICAL}/include/libical/ical.h
    done
}

patch_libical_includes()
{
    #sed -i 's#<icalcomponent.h>#<libical/icalcomponent.h>#g' ${BUILD_DIR_LIBICAL}/include/libicalss/icalss.h
    #sed -i 's#<icalcomponent.h>#<libical/icalcomponent.h>#g' ${BUILD_DIR_LIBICAL}/include/libicalss/icalss.h
    #sed -i 's#<icalgauge.h>#<libical/icalgauge.h>#g' ${BUILD_DIR_LIBICAL}/include/libicalss/icalss.h
    #sed -i 's#<icalset.h>#<libical/icalset.h>#g' ${BUILD_DIR_LIBICAL}/include/libicalss/icalss.h
    #sed -i 's#<icalcluster.h>#<libical/icalset.h>#g' ${BUILD_DIR_LIBICAL}/include/libicalss/icalss.h
    #sed -i 's#<libicalss#<libical#g' ${BUILD_DIR_LIBICAL}/include/libicalss/icaldirsetimpl.h
    #sed -i 's#<libicalss#<libical#g' ${BUILD_DIR_LIBICAL}/include/libicalss/icalfilesetimpl.h

    # confuses vala-gen-introspect
    sed -i 's#@par ##g' ${BUILD_DIR_LIBICAL}/include/libical/ical.h
    sed -i 's#@brief ##g' ${BUILD_DIR_LIBICAL}/include/libical/ical.h
}

init_packages()
{
    mkdir -p ${PKG_DIR}
    rm -rf ${PKG_DIR}/*

    for PACKAGE in $LIBICAL_PACKAGES; do
        mkdir -p "${PKG_DIR}/$PACKAGE"
        echo "${BUILD_DIR_LIBICAL}/include/$PACKAGE" > "${PKG_DIR}/$PACKAGE/$PACKAGE.files"
        echo "${BUILD_DIR_LIBICAL}/lib/$PACKAGE.a" >> "${PKG_DIR}/$PACKAGE/$PACKAGE.files"
        echo "$PACKAGE" > "${PKG_DIR}/$PACKAGE/$PACKAGE.namespace"
    done

    PACKAGE="${EDATASERVER_PACKAGE}"
    mkdir -p "${PKG_DIR}/$PACKAGE"
    echo "${BUILD_DIR}/include/evolution-data-server-3.2/libedataserver" >> "${PKG_DIR}/$PACKAGE/$PACKAGE.files"
    echo "${BUILD_DIR}/lib/libedataserver-1.2.so" >> "${PKG_DIR}/$PACKAGE/$PACKAGE.files"
    echo "E" > "${PKG_DIR}/$PACKAGE/$PACKAGE.namespace"
    cp ${BUILD_DIR}/lib/pkgconfig/libedataserver-1.2.pc $PKG_DIR/$PACKAGE/$PACKAGE.pc

    PACKAGE="${ECALENDAR_PACKAGE}"
    mkdir -p "${PKG_DIR}/$PACKAGE"
    echo "${BUILD_DIR}/include/evolution-data-server-3.2/libecal" >> "${PKG_DIR}/$PACKAGE/$PACKAGE.files"
    echo "${BUILD_DIR}/lib/libecal-1.2.so" >> "${PKG_DIR}/$PACKAGE/$PACKAGE.files"
    echo "E" > "${PKG_DIR}/$PACKAGE/$PACKAGE.namespace"
    cp ${BUILD_DIR}/lib/pkgconfig/libecal-1.2.pc $PKG_DIR/$PACKAGE/$PACKAGE.pc
}

init_vapi_dir()
{
    mkdir -p ${OUTPUT_DIR}
    rm -f ${OUTPUT_DIR}/*
    cp -v ${VAPI_DIR}/*.metadata "${OUTPUT_DIR}"
}

generate_gi()
{
    ALL_PACKAGES="${LIBICAL_PACKAGES} ${EDATASERVER_PACKAGE} ${ECALENDAR_PACKAGE} "
    for PACKAGE in $ALL_PACKAGES; do
        cd "${PKG_DIR}"
        export PKG_CONFIG_PATH="${PKG_DIR}/${PACKAGE}"
        echo "*** $PACKAGE.gi *** " >> $LOG 2>&1
        vala-gen-introspect $PACKAGE $PACKAGE >> $LOG 2>&1
        cp ${PKG_DIR}/$PACKAGE/$PACKAGE.gi ${OUTPUT_DIR}
    done
    unset PKG_CONFIG_PATH
}

patch_gi()
{
    sed -i 's#type="enum #type="#g' ${OUTPUT_DIR}/libical.gi
    sed -i 's#<namespace name="libical">#<namespace name="iCal">#g' ${OUTPUT_DIR}/libical.gi
    sed -i 's#type="struct #type="#g' ${OUTPUT_DIR}/libical.gi

    # there are two definitions of error in E.SExp, we rename the method
    sed -i 's#name="error" symbol="e_sexp_error">#name="get_error" symbol="e_sexp_error">#g' ${OUTPUT_DIR}/libedataserver-1.2.gi
    # there are two definitions of open in E.Client (signal and property), we delete the property
    sed -i '/<property name="opened"/d' ${OUTPUT_DIR}/libedataserver-1.2.gi

    sed -i 's#xmlNodePtr#xmlNode#g' ${OUTPUT_DIR}/libedataserver-1.2.gi
    sed -i 's#xmlDocPtr#xmlDoc#g' ${OUTPUT_DIR}/libedataserver-1.2.gi
    sed -i 's#xmlChar#gchar#g' ${OUTPUT_DIR}/libedataserver-1.2.gi # DOUBLECHECK: xmlChar* = gchar*
    sed -i 's#GData#void#g' ${OUTPUT_DIR}/libedataserver-1.2.gi # DOUBLECHECK: what is GData* ?
    sed -i 's#ECredentialsPrivate#void#g' ${OUTPUT_DIR}/libedataserver-1.2.gi # ECredentials.priv should not appear
    sed -i 's#jmp_buf#void\*#g' ${OUTPUT_DIR}/libedataserver-1.2.gi # DOUBLECHECK: what is jump_buf?
}

generate_vapi()
{
    for PACKAGE in $LIBICAL_PACKAGES; do
        echo "*** $PACKAGE.vapi *** " >> $LOG 2>&1
        vapigen -d ${OUTPUT_DIR} --library $PACKAGE --metadatadir=${OUTPUT_DIR} ${OUTPUT_DIR}/$PACKAGE.gi >> $LOG 2>&1
    done

    PACKAGE="${EDATASERVER_PACKAGE}"
    echo "*** $PACKAGE.vapi *** " >> $LOG 2>&1
    vapigen -d ${OUTPUT_DIR} \
        --vapidir=${OUTPUT_DIR} \
        --pkg gconf-2.0 \
        --pkg libgdata \
        --pkg gio-2.0 \
        --pkg libxml-2.0 \
        --pkg libical \
        --library "$PACKAGE" \
        --metadatadir=${OUTPUT_DIR} \
        ${OUTPUT_DIR}/$PACKAGE.gi \
        >> $LOG 2>&1

    PACKAGE="${ECALENDAR_PACKAGE}"
    echo "*** $PACKAGE.vapi *** " >> $LOG 2>&1
    vapigen -d ${OUTPUT_DIR} \
        --vapidir=${OUTPUT_DIR} \
        --pkg gconf-2.0 \
        --pkg libedataserver-1.2 \
        --pkg gio-2.0 \
        --pkg libxml-2.0 \
        --pkg libsoup-2.4 \
        --pkg libical \
        --library "$PACKAGE" \
        --metadatadir=${OUTPUT_DIR} \
        ${OUTPUT_DIR}/$PACKAGE.gi \
        >> $LOG 2>&1
}

patch_vapi()
{
    sed -i '/public enum CredentialsPromptFlags/ i\\t[Flags]' ${OUTPUT_DIR}/libedataserver-1.2.vapi
}

install_vapi()
{
    cp -v ${OUTPUT_DIR}/*.vapi "${VAPI_DIR}"
}

get_archives
unpack_archives
patch_libical
clean_build_dir
build_libical
build_eds
clean_install_dir
copy_gi_deps
add_libical_typedefs
patch_libical_includes
init_packages
init_vapi_dir
generate_gi
patch_gi
generate_vapi
patch_vapi
install_vapi

