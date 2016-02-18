#!/bin/bash

# Pull down VIIRS tiffs for mosaic
DATA_DIR='/srv/geoserver/data/landsat'
CONFIG_DIR='/srv/geoserver/mosaics/landsat'
mkdir -p ${DATA_DIR}
mkdir -p ${CONFIG_DIR}
cd ${DATA_DIR}

declare -a arrDays=('025' '057' '073' '105' '121' '153' '201' '217' '249' '281' '313' '345')

for d in ${arrDays[@]}
do
    # Retrieve RGB landsat bands
    wget 'http://landsat-pds.s3.amazonaws.com/L8/027/039/LC80270392015'"${d}"'LGN00/LC80270392015'"${d}"'LGN00_B2.TIF'
    wget 'http://landsat-pds.s3.amazonaws.com/L8/027/039/LC80270392015'"${d}"'LGN00/LC80270392015'"${d}"'LGN00_B3.TIF'
    wget 'http://landsat-pds.s3.amazonaws.com/L8/027/039/LC80270392015'"${d}"'LGN00/LC80270392015'"${d}"'LGN00_B4.TIF'
    # Reproject images
    gdalwarp -t_srs EPSG:3857 LC80270392015"${d}"LGN00_B2.TIF LC80270392015"${d}"LGN00_B2_PROJECTED.TIF
    gdalwarp -t_srs EPSG:3857 LC80270392015"${d}"LGN00_B3.TIF LC80270392015"${d}"LGN00_B3_PROJECTED.TIF
    gdalwarp -t_srs EPSG:3857 LC80270392015"${d}"LGN00_B4.TIF LC80270392015"${d}"LGN00_B4_PROJECTED.TIF
    # Combine bands into one RGB image
    convert -combine LC80270392015"${d}"LGN00_B4_PROJECTED.TIF LC80270392015"${d}"LGN00_B3_PROJECTED.TIF LC80270392015"${d}"LGN00_B2_PROJECTED.TIF LC80270392015"${d}"LGN00_RGB.TIF
    # Adjust image color
    convert -channel B -gamma 0.975 -channel G -gamma 0.99 -channel RGB -sigmoidal-contrast 50x13% LC80270392015"${d}"LGN00_RGB.TIF LC80270392015"${d}"LGN00_RGB_CORRECTED.TIF
    # Convert to 8 bit image
    convert -depth 8 LC80270392015"${d}"LGN00_RGB_CORRECTED.TIF LC80270392015"${d}"LGN00_RGB_CORRECTED_8bit.TIF
    # Retrieve geo data from base image and reapply it to the corrected 8-bit RGB image
    listgeo -tfw LC80270392015"${d}"LGN00_B4_PROJECTED.TIF
    mv LC80270392015"${d}"LGN00_B4_PROJECTED.tfw LC80270392015"${d}"LGN00_RGB_CORRECTED_8bit.tfw
    gdal_edit.py -a_srs EPSG:3857 LC80270392015"${d}"LGN00_RGB_CORRECTED_8bit.TIF
    # Toss all input files
    ls | grep -v _8bit.TIF | xargs rm
done

# Copy in the mosaic configuration
cp /tmp/geoserver/landsat/* ${CONFIG_DIR}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
curl -v -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "<workspace><name>mosaic</name></workspace>" http://localhost:8080/geoserver/rest/workspaces
curl -v -u admin:geoserver -XPOST -T ${DIR}/landsat-store.xml -H "Content-type: text/xml" http://localhost:8080/geoserver/rest/workspaces/mosaic/coveragestores
curl -v -u admin:geoserver -XPOST -T ${DIR}/landsat.xml -H "Content-type: text/xml" http://localhost:8080/geoserver/rest/workspaces/mosaic/coveragestores/landsat/coverages
