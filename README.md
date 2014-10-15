sender API
Api1(params,function(err,result){
	//Handle result
});

//receiving API
client.on('Api1',function(params,callback){
	//process params
	if(err){
		callback(err,null);
		return;
	}
	callback(null,result);
});
