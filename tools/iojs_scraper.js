var http    = require('https'),
    fs      = require('fs'),
    path    = require('path'),
    baseUrl = "https://github.com/iojs/io.js.git";

function generateNodeFile (item) {
  var version   = "iojs-" + item.version.replace(/^v/,''),
    installLine = 'install_git "' + version + '" "' + baseUrl  + '" "' + item.version + '" standard',
    filePath    = path.join(__dirname, '../share/node-build', version);

  fs.exists(filePath,function(exists){
    if(!exists){
      fs.writeFile(filePath, installLine, function(err){

        if(err) {
          console.log(err);
        } else {
          console.log(version + ' file writen');
        }
      });
    }
  });
}

exports.versions = function getVersions () {
  http.get("https://iojs.org/download/release/index.json", function(res) {
    var versions = "";
    res.on('data', function(data) {
      versions += data;
    });

    res.on('end', function() {
      versions = JSON.parse(versions);
      versions.forEach(generateNodeFile);
    });
  });
};
