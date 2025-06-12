<#
.SYNOPSIS
	List crypto rates
.DESCRIPTION
	This PowerShell script queries the current crypto exchange rates from cryptocompare.com and lists it in USD
.EXAMPLE
	PS> ./list-crypto-rates.ps1

	CRYPTOCURRENCY               US$                    €UR                    CN¥Y                    JPY
	--------------               ---                    ---                    ---                    ---
	1 Bitcoin (BTC) =            97309.81               94385.57               38800                  14798679.56
	...
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function ListCryptoRate { param([string]$Symbol, [string]$Name)
	$rates = (Invoke-WebRequest -URI "https://min-api.cryptocompare.com/data/price?fsym=$Symbol&tsyms=USD" -userAgent "curl" -useBasicParsing).Content | ConvertFrom-Json
	New-Object PSObject -property @{ 'CRYPTOCURRENCY' = "1 $Name ($Symbol) ="; 'US$' = "$($rates.USD)"; }
}

function ListCryptoRates { 
	ListCryptoRate BTC   "Bitcoin"
	ListCryptoRate ADA   "Cardano"
	ListCryptoRate DOGE  "Dogecoin"
	ListCryptoRate ETH   "Ethereum"
	ListCryptoRate TRUMP "Official Trump"
	ListCryptoRate DOT   "Polkadot"
	ListCryptoRate SOL   "Solana"
	ListCryptoRate XRP   "XRP"
	ListCryptoRate SHIB  "Shiba Inu"
	ListCryptoRate WIF   "DogWiFiHat"
    ListCryptoRate MEW   "Cat In Dog's World"
}

try {
	ListCryptoRates | Format-Table -property @{e='CRYPTOCURRENCY';width=28},'US$'
	Write-Host "(by https://www.cryptocompare.com • Crypto is volatile and unregulated • Capital at risk • Taxes may apply)"
	exit 0 # success
} catch {
	"⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}