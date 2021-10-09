var MuonFeargame = artifacts.require('./MuonFeargame.sol')

module.exports = function (deployer) {
	deployer.then(async () => {
		await deployer.deploy(MuonFeargame);
	})
}
