var http = require('http');
var fs = require('fs');
var path = require('path');
var baseUrl = "http://nodejs.org/dist/";

exports.versions = function getVersions () {
  http.get(baseUrl, function(res){
    if( res.statusCode === 200){

      var responseData = "",
        digestableUrls

      res.on('data', function( data ){
        responseData = responseData + data
      })

      res.on('end', function(){
        digestableUrls = responseData.match(/href=\"v\d\.[\d]{0,2}\.[\d]{0,2}\/\"/g)
        digestableUrls = digestableUrls.map(function( url ){
          return url.replace(/href=\"([^"]*)\"/, "$1")
        })

        digestableUrls.forEach(function( url ){
          generateNodeFile(url.substring(0, url.length - 1))
        })
      })

    } else {
      console.log('response "' + res.status + '" from http://nodejs.org/dist/')
    }
  })
}

// private

function generateNodeFile( version ){
  var shaUrl = baseUrl + version + "/";
  var shaData, shaLine, installLine, parts, filePath;

  if(/^(v4)/g.test(version)) {
    shaUrl += "SHASUMS256.txt";
    checksum = /[\da-zA-Z]{64}  node-v[\d]{1,2}\.[\d]{1,2}\.[\d]{1,2}.tar.gz/gi;
  } else {
    shaUrl += "SHASUMS.txt";
    checksum = /[\da-zA-Z]{40}  node-v[\d]{1,2}\.[\d]{1,2}\.[\d]{1,2}.tar.gz/gi;
  }

  http.get(shaUrl, function(res){
    shaData = ''

    res.on('data', function(data){
      shaData = shaData + data
    });

    res.on('end', function(){
      shaLine = shaData.match(checksum)

      if(shaLine && shaLine.length){
        parts = shaLine[0].split('  ')
        //this is gnarly, oh well
        //install_package "node-v0.10.0" "http://nodejs.org/dist/v0.10.0/node-v0.10.0.tar.gz#7321266347dc1c47ed2186e7d61752795ce8a0ef"
        installLine = 'install_package "node-' + version + '" "' + baseUrl + version + '/' + parts[1] + '#'+parts[0]+'"\n'
        filePath = path.join(__dirname, '../share/node-build', version.substring(1))
        fs.exists(filePath,function(exists){

          if(!exists){

            fs.writeFile(filePath, installLine, function(err){
              if(err)
                console.log(err)
              else
                console.log( version.substring(1) + ' file writen')
            })
          }
        })
      }
    })
  })
};
