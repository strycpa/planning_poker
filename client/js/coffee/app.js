// Generated by CoffeeScript 1.6.3
var j3r;

j3r = {};

j3r.App = (function() {
  function App(name) {
    this.name = name;
    this.socket = io.connect('http://192.168.218.98:1107');
    this.socket.on('mrdka', function(data) {
      return console.log(data);
    });
  }

  App.prototype.getName = function() {
    alert(this.name);
  };

  return App;

})();
