mkdir workfiles
cd workfiles
rm -rf data-xml
wget -c -e robots=off -r -l inf --no-remove-listing -nH --no-parent -R 'index.html*'  http://childes.talkbank.org/data-xml/
find data-xml -name "*.zip" | while read filename; do unzip -o -d "`dirname "$filename"`" "$filename"; done;
find data-xml -name "*.zip" | xargs rm 
