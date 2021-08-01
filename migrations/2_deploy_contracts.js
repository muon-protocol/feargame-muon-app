var MuonFeargame = artifacts.require('./MuonFeargame.sol')
var muon = artifacts.require('./MuonV01.sol')

function parseArgv(){
	let args = process.argv.slice(2);
	let params = args.filter(arg => arg.startsWith('--'))
	let result = {}
	params.map(p => {
		let [key, value] = p.split('=');
		result[key.slice(2)] = value === undefined ? true : value
	})
	return result;
}

module.exports = function (deployer) {
	deployer.then(async () => {
		let params = parseArgv()

		// let muonAddress = null
		// if(!!params['muonAddress']){
		// 	muonAddress = params['muonAddress'];
		// }
		// else{
		// 	let deployedMuon =  await deployer.deploy(muon);
		// 	muonAddress = deployedMuon.address;
		// }
		await deployer.deploy(MuonFeargame)
	})
}
