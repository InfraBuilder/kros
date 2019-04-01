# Create configs/cluster.yaml from upstream cluster.yaml +
# cluster.yaml.add (latter with autogenerated `nodes:` entries for
# `/srv/ceph/...` diretories for ceph storage)
mod_cluster() {
    local cluster_extra=${2}.add
    echo "Creating extra custom '${cluster_extra}' per-node setup ..."
    ${MY_DIR}/generate-nodes.sh ${NODES:?} > ${cluster_extra}
    test -s ${cluster_extra} || {
        echo "FATAL: ${cluster_extra} in zero" ;
        exit 1
    }
    set -e
    (
        sed -e '/useAllNodes:/s/true/false/' \
            -e '/Cluster.level.list/,$d' \
            -e '/size: 1/s/1/3/' \
            ${1} && \
        cat ${cluster_extra}
    ) > ${2}
}
# Until we have blustore ready (umcloud/kros#4), use RF=2
# for default replicapool
mod_storageclass() {
    sed -e '/size: 1/s/1/2/' ${1} > ${2}
}
mod_operator() {
    cp -p ${1} ${2}
}
mod_toolbox() {
    cp -p ${1} ${2}
}

prep_manifests() {
    # Set "func" below to mod_<manifestname>
    local func
    for f in ${ROOK_MANIFESTS}; do
        printf -v func mod_$f
        ${func} ${MANIFESTS_DIR}/$f.yaml ${CONFIG_DIR}/$f.yaml
    done
}

MY_DIR=$(dirname ${0})
MANIFESTS_DIR=${1:?missing MANIFESTS_DIR}
CONFIG_DIR=${2:?missing CONFIG_DIR}
ROOK_MANIFESTS="operator cluster storageclass toolbox"

shift 2
NODES=${*:? missing args: NODES}
set -e
prep_manifests
