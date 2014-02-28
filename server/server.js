var express = require('express'),
    fs      = require('fs'),
    path    = require('path');
var app = express();

app.use(express.logger());
app.use(express.static(__dirname + '/public'));

app.get('/hello', function(req, res) {
  var body = 'Helo World!';
  res.setHeader('Content-Type', 'text/plain');
  res.setHeader('Content-Length', Buffer.byteLength(body));
  res.end(body);
});

app.post('/article', function(req, res) {
  var artid = (Math.random() + 1).toString(36).substr(2, 5);
  res.send({id: artid});
});

app.put('/article/:artid/:filepath', function(req, res) {
  // console.log("article id:  " + req.params.artid + ", filepath: " + req.params.filepath);
  savedir = path.join('uploads', req.params.artid);
  fs.exists(savedir, function(exists) {
    if(!exists) {
      fs.mkdirSync(savedir);
    }
    req.pipe(fs.createWriteStream(path.join(savedir, req.params.filepath)));
    res.send({article_id: req.params.artid, file_path: req.params.filepath});
  });
});

app.listen(3000);
console.log('Listening on port 3000');
