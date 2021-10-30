var MuonFeargame = artifacts.require('./MuonFeargameV2.sol')

module.exports = function (deployer) {
	deployer.then(async () => {
		await deployer.deploy(MuonFeargame);
	})
}
