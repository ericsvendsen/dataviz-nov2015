#!/bin/bash

# Pull down VIIRS tiffs for mosaic
DATA_DIR='/srv/geoserver/data/landsat'
CONFIG_DIR='/srv/geoserver/mosaics/landsat'
mkdir -p ${DATA_DIR}
mkdir -p ${CONFIG_DIR}
cd ${DATA_DIR}

#declare -a arrDays=('025' '073' '105' '121' '153' '201' '217' '249' '281' '313' '345')
declare -a arrDays=('025' '073')

for d in ${arrDays[@]}
do
    wget 'http://landsat-pds.s3.amazonaws.com/L8/027/039/LC80270392015'"${d}"'LGN00/LC80270392015'"${d}"'LGN00_B2.TIF'
    wget 'http://landsat-pds.s3.amazonaws.com/L8/027/039/LC80270392015'"${d}"'LGN00/LC80270392015'"${d}"'LGN00_B3.TIF'
    wget 'http://landsat-pds.s3.amazonaws.com/L8/027/039/LC80270392015'"${d}"'LGN00/LC80270392015'"${d}"'LGN00_B4.TIF'
    convert -combine LC80270392015"${d}"LGN00_B4.TIF LC80270392015"${d}"LGN00_B3.TIF LC80270392015"${d}"LGN00_B2.TIF LC80270392015"${d}"LGN00_RGB.TIF
    convert -depth 8 LC80270392015"${d}"LGN00_RGB.TIF LC80270392015"${d}"LGN00_RGB_8bit.TIF
    listgeo -tfw LC80270392015"${d}"LGN00_B4.TIF
    mv LC80270392015"${d}"LGN00_B4.tfw LC80270392015"${d}"LGN00_RGB_8bit.tfw
    gdal_edit.py -a_srs EPSG:32614 LC80270392015"${d}"LGN00_RGB_8bit.TIF
    ls | grep -v _8bit.TIF | xargs rm
    #wget 'https://s3.amazonaws.com/ais-landsat/LC80270392015'"${d}"'LGN00.tar.gz'
    #tar -xzvf 'LC80270392015'"${d}"'LGN00.tar.gz'
    #rm 'LC80270392015'"${d}"'LGN00.tar.gz'
    #gdal_merge.py -separate -o LC80270392015025LGN00_BV.TIF LC80270392015025LGN00_B4.TIF LC80270392015025LGN00_B3.TIF LC80270392015025LGN00_B2.TIF
    # Toss all input files
    #ls | grep -v _BV.TIF | xargs rm
done

# Create inner tiles and overviews to ensure snappy rendering performance
#for FILE in `ls *.TIF`; do
#    echo ${FILE}
#    gdal_translate -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512" ${FILE} tiled_${FILE}
#    gdaladdo -r average tiled_${FILE} 2 4 8 16 32
#    mv tiled_${FILE} ${FILE}
#done

# Copy in the mosaic configuration
cp /tmp/geoserver/landsat/* ${CONFIG_DIR}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
curl -v -u admin:geoserver -XPOST -H "Content-type: text/xml" -d "<workspace><name>mosaic</name></workspace>" http://localhost:8080/geoserver/rest/workspaces
curl -v -u admin:geoserver -XPOST -T ${DIR}/landsat-store.xml -H "Content-type: text/xml" http://localhost:8080/geoserver/rest/workspaces/mosaic/coveragestores
curl -v -u admin:geoserver -XPOST -T ${DIR}/landsat.xml -H "Content-type: text/xml" http://localhost:8080/geoserver/rest/workspaces/mosaic/coveragestores/landsat/coverages
