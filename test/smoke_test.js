var easy_rpc = require('../../easy-rpc');

var api_peer1 = new easy_rpc('peer1','peer2',['hello_peer1']);
var api_peer2 = new easy_rpc('peer2','peer1',[]);

api_peer1.on('connect',function(){
	console.log('on connect event 1');
	api_peer1.on('hello_peer1',function(params,callback){
		if(!params.hasOwnProperty('mesg')){
			callback(new Error('no mesg propert'));
			return;
		}
		callback(null,{loop_back_result:params.mesg});
	});
});

api_peer2.on('connect',function(){
	console.log('on connect event 2');
	api_peer2.hello_peer1({mesg:'Hi from peer2'},function(err,result){
		if(err)
			throw err;

		console.log(result);
	});
});