#!/bin/bash

# Pull down VIIRS tiffs for mosaic
DATA_DIR='/srv/geoserver/data/hotspots'
CONFIG_DIR='/srv/geoserver/mosaics/hotspots'
mkdir -p ${DATA_DIR}
mkdir -p ${CONFIG_DIR}
cd ${DATA_DIR}

# Copy in the mosaic configuration
cp /tmp/geoserver/hotspots/* ${CONFIG_DIR}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
curl -v -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "<workspace><name>mosaic</name></workspace>" http://localhost:8080/geoserver/rest/workspaces
curl -v -u admin:geoserver -XPOST -T ${DIR}/hotspots-store.xml -H "Content-type: text/xml" http://localhost:8080/geoserver/rest/workspaces/mosaic/coveragestores
curl -v -u admin:geoserver -XPOST -T ${DIR}/hotspots.xml -H "Content-type: text/xml" http://localhost:8080/geoserver/rest/workspaces/mosaic/coveragestores/hotspots/coverages
