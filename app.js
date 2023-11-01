const express = require('express');
const exphbs  = require('express-handlebars'); // templating engine for generating dynamic HTML and other markup in web applications
const bodyParser = require('body-parser'); // handle various types of data in the request body
const { Web3 } = require('web3'); // used for geth
const fs = require('fs'); // require the File System module
const ethers = require('ethers');
const app = express(); // create Express server
const port = 3000;
const web3 = new Web3('https://mainnet.infura.io/v3/db330f04a5e0472d956185e545919dfa'); // replace with your Geth node URL

// read the JSON file containing the contract artifact
const contractArtifact = JSON.parse(fs.readFileSync('artifacts/contracts/Crowdfunding.sol/Crowdfunding.json', 'utf8'));

const contractAddress = '0xB139FB0b0202D115B88A5a81957BbeFA93d04606'; // deployed contract address
const contractABI = contractArtifact.abi;

const crowdfundingContract = new web3.eth.Contract(contractABI, contractAddress);
const privateKey = '7aa4ba12913cfe97125d7a9c4b0b1b7eb8ac9e88abbde7c9e176c8bedd052aea'; // contract developer private key

// configure and setup handlebars
var hbs = exphbs.create({});
app.engine('handlebars', hbs.engine);
app.set('view engine', 'handlebars');

// middleware to parse the HTTP request body, allowing you to read data submitted via POST requests
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// handling GET requests for "/"
app.get('/', (req, res) => {
    res.render('metamask_login', { layout: false });
})

// handling POST requests for "/"
app.post('/', async (req, res, next) => {

    // get current ethereum address
    const ethereumAddress = req.body.address;
    console.log("Logged in with: %s", ethereumAddress);

    return res.status(200).json({ redirectTo: '/dashboard' }) // if the request to okay then head to dashboard

});

// handling GET requests for "/dashboard"
app.get('/dashboard', (req, res) => {

    crowdfundingContract.methods.returnAllProjects().call((error, result) => {
    if (!error) {
        console.log("All deployed projects:", result);
    } else {
        console.error("Error fetching projects:", error);
    }
    });

    res.render('dashboard', { layout: false });
})

// handling GET requests for "/create_campaign"
app.get('/create_campaign', (req, res) => {
    res.render('create_campaign', { layout: false });
})

// handling POST requests for "/create_campaign"
app.post('/create_campaign', async (req, res, next) => {

    // get current ethereum address that is used to create the campaign
    const ethereumAddress = req.body.address;
    console.log("Creating campaign using: %s", ethereumAddress);

    // get form details
    const title = req.body.title;
    const description = req.body.description;
    const funding_target = req.body.funding_target;
    const minimum_contribution = req.body.minimum_contribution;

    // printing to verify info
    console.log('Title:', title);
    console.log('Description:', description);
    console.log('Funding Target:', funding_target.toString());
    console.log('Minimum Contribution:', minimum_contribution.toString());

    const target_wei = ethers.utils.parseEther(funding_target.toString());
    const minimum_wei = ethers.utils.parseEther(minimum_contribution.toString());

    console.log('Funding Target in Wei:', target_wei.toString());
    console.log('Minimum Contribution in Wei:', minimum_wei.toString());

    const campaign_data = crowdfundingContract.methods.requestProjectCreation(
        target_wei.toString(),
        minimum_wei.toString(),
        title,
        description
    ).encodeABI();

    const nonce = await web3.eth.getTransactionCount(ethereumAddress, 'pending');

    const campaign_object = {
        from: ethereumAddress,
        to: contractAddress,
        data: campaign_data,
        gas: '1000000000000000', // set the gas limit according to your requirements
        maxFeePerGas: '70000000000',
        maxPriorityFeePerGas: '1000000000',
        nonce: nonce
    };

    try {
        const signedTx = await web3.eth.accounts.signTransaction(campaign_object, privateKey);
        const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
        return res.status(200).json({ redirectTo: '/dashboard' }); // if the request to okay then head to dashboard

    } catch (error) {
        console.error("Transaction error:", error);
    }

})

app.listen(port, () => {
    console.log(`Application running on: http://localhost:${port}`);
});