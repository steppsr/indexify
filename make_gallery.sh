#!/bin/bash

# indexify
# Bash script to create a general purpose NFT Gallery for Datalayer NFT collection on the Chia Blockchain. _Or really any NFT collection in a source folder._

# ### Prerequisites
# * jq
# * tr
# * curl

# ### Parameters
# Parameter 1 <build_folder> must be the folder with the NFT files.  i.e.  `./build` or `./public_html`

# ### Example of basic folder structure for collection
# build
#    ├─ images
#        ├─ 01.png
#        └─ 02.png
#    ├─ metadata
#        ├─ 01.json
#        └─ 02.json
#    ├─ icon.png
#    ├─ banner.png
#    └─ license.md

# * Assumption 1 - <build_folder> contains a subfolder named `images` containing all the images of the NFTs.
# * Assumption 2 - <build_folder> contains a subfolder named `metadata` containing all the JSON files for the metadata of the NFTs.
# * Assumption 3 - <build_folder> contains an image named `icon.png`, `icon.jpg`, or `icon.gif` containing the icon for the collection.
# * Assumption 4 - <build_folder> contains an image named `banner.png`, `banner.jpg`, or `banner.gif` containing the banner for the collection.
# * Assumption 5 - <build_folder> contains a file named `license.md`, `license.pdf`, or `license.txt` contain the license for the collection.

# * Note 1 - The Collection data will be pulled from the first metadata file in the `metadata` folder.
# * Note 2 - Output will be a file named `index.html` in the build_folder.

# # USAGE
# bash make_gallery.sh <collection_name>/<build_folder>

# Real Example:
# bash make_gallery.sh BattleKats/build

# --------------------------------------

# check if build folder path is given as an argument
if [ -z "$1" ]; then
	echo "Usage: $0 <build_folder_path>"
	exit 1
fi

build_folder="$1"
output_html="$build_folder/index.html"

# check if the folders exists
if [ ! -d "$build_folder" ]; then
	echo "Error: $build_folder not found."
	exit 1
fi
if [ ! -d "$build_folder/images" ]; then
	echo "Error: $build_folder/images not found."
	exit 1
fi
if [ ! -d "$build_folder/metadata" ]; then
	echo "Error: $build_folder/metadata not found."
	exit 1
fi

working_folder="${build_folder#./}"

# get the icon file
icon_files=("icon.png" "icon.jpg" "icon.gif")
icon_file=""
for file in "$working_folder/${icon_files[@]}"; do
    if [ -e "$file" ]; then
        icon_file=$(basename "$file")
        break  # Stop the loop once a file is found
    else
        echo "$file does not exist."
    fi
done

# get the banner file
banner_files=("banner.png" "banner.jpg" "banner.gif")
banner_file=""
for file in "$working_folder/${banner_files[@]}"; do
    if [ -e "$file" ]; then
        banner_file=$(basename "$file")
        break  # Stop the loop once a file is found
    else
        echo "$file does not exist."
    fi
done

# get the license file
license_files=("license.md" "license.pdf" "license.txt" "license.doc")
license_file=""
for file in "$working_folder/${license_files[@]}"; do
    if [ -e "$file" ]; then
        license_file=$(basename "$file")
        break  # Stop the loop once a file is found
    else
        echo "$file does not exist."
    fi
done

# first metadata file we will pull the collection data out. (we want the collection info before starting to output the HTML page)
appdir=$(pwd)
cd $build_folder/metadata
md_list=$(ls -1 *.json)
cd $appdir

first=$(echo $md_list | tr ' ' '\n' | head -n 1)
metadata=$(jq . $build_folder/metadata/"$first")
collection_name=$(echo $metadata | jq '.collection.name' | cut --fields 2 --delimiter=\")

# use collection name to pull collection id from Mintgarden. https://api.mintgarden.io/search?query="COLLECTION_NAME"
# use collection id to pull collection data from Mintgarden. https://api.mintgarden.io/collections/col13c7w72dvywudk76fj79af77022r2vez6p65t6hmsj7vtrj5c6tcsz9mwkq
# now lets get some extra collection info from the Mintgarden API
urlencoded_collection_name=$(echo -n "$collection_name" | jq -s -R -r @uri)
search=$(curl -s https://api.mintgarden.io/search?query="$urlencoded_collection_name" | jq '.collections')
collection_id=$(echo "$search" | jq -r --arg name "$collection_name" '.[] | select(.name == $name) | .id')
mg_col_data=$(curl -s https://api.mintgarden.io/collections/$collection_id)

creator_did=$(echo "$mg_col_data" | jq '.creator.encoded_id' | cut --fields 2 --delimiter=\" | sed 's/null//g')
creator_name=$(echo "$mg_col_data" | jq '.creator.name' | cut --fields 2 --delimiter=\" | sed 's/null//g')
creator_bio=$(echo "$mg_col_data" | jq '.creator.bio' | cut --fields 2 --delimiter=\" | sed 's/null//g')
creator_website=$(echo "$mg_col_data" | jq '.creator.website' | cut --fields 2 --delimiter=\" | sed 's/null//g')
creator_twitter=$(echo "$mg_col_data" | jq '.creator.twitter_handle' | cut --fields 2 --delimiter=\" | sed 's/null//g')
description=$(echo "$mg_col_data" | jq '.description' | cut --fields 2 --delimiter=\" | sed 's/null//g')

# the did is too long to look good in the format so lets create a short version too
creator_did_short="${creator_did:0:30}...${creator_did: -15}"

cat <<EOF > "$output_html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$collection_name</title>
    <style>
		:root {
			--attrborder:	#333333;
			--linkcolor:	#2A9FD6;
			--background:	#D9D9DB;
			--foreground:	#4A7933;
			--imgborder:	#DDDDDD;
			--copied:		#6A50A8;
			--nftdetail:	#EEDDEE;
		}
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: var(--background);
			opacity: 1;
        }
		#banner {
            width: 100%;
            max-width: 100vw;
            height: auto;
            opacity: 0.75; /* Set opacity to 75% for the banner image */
        }
		#creator {
			float:left;
			margin-top: -5px;
			margin-left: 0px;
			margin-right: 16px;
			font-family: 'Ubuntu', san-serif;
			font-size: 1em;
			font-weight: 400;
			line-height: 22px;
			display: inline-block;
			background: var(--background);
			padding: 20px;
			height:650px;
			max-width: 475px;
		}
		#creator img {
			border-radius: 5%;
		}
		#creator_did {
			cursor: pointer;
			color: var(--foreground);
		}
		#collectionID {
			cursor: pointer;
			color: var(--foreground);
		}
		.nftid_icon {
			cursor: pointer;
			color: var(--foreground);
		}
		.owner_did {
			cursor: pointer;
			color: var(--foreground);
		}
		.owner_address {
			cursor: pointer;
			color: var(--foreground);
		}
		#nft_details {
			background: var(--nftdetail);
		}
       .gallery {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 10px;
            padding: 20px;
        }
        .gallery img {
            max-width: 100%;
            height: auto;
            border: 1px solid var(--imgborder);
            border-radius: 8px;
            transition: transform 0.3s ease-in-out;
            cursor: pointer;
        }
        .gallery img:hover {
            transform: scale(1.15);
        }
		#gallery_title { padding-bottom: 10px; }
		.h1 {
            text-align: left;
            font-family: 'Ubuntu', sans-serif;
            font-size: 5em;
            font-weight: 700;
            display: flex;
            align-items: center;
        }
        .h3 {
            text-align: left;
            font-family: 'Ubuntu', sans-serif;
            font-size: 2.5em;
            font-weight: 600;
			display: flex;
        }
        .h4 {
            text-align: left;
            font-family: 'Ubuntu', sans-serif;
            font-size: 1.75em;
            font-weight: 500;
			display: flex;
        }
        .h5 {
            text-align: left;
            font-family: 'Ubuntu', sans-serif;
            font-size: 1.33em;
            font-weight: 500;
			display: flex;
        }
		.h6 {
			text-align: left;
			font-family: 'Ubuntu', san-serif;
			font-size: 1em;
			font-weight: 400;
			display: flex;
		}
		.copied {
			color: var(--copied);
			transition: color 1s ease;
		}
		a {
			text-decoration: none;
		}
		#nft_description { font-weight:normal; font-style:italic; font-size: 0.8rem; }
		.nft { font-size: 0.8rem; font-family: 'Ubuntu', sans-serif; }
		.minted_at { font-size: 0.7rem; font-family: 'Ubuntu', sans-serif; }
		.data td { font-size: 0.9rem; font-family: 'Ubuntu', sans-serif; }
		#creator_title { font-size: 1.1rem; font-weight: 500; font-family: 'Ubuntu', sans-serif; }
		#collection_stats_title { font-size: 1.1rem; font-weight: 500; font-family: 'Ubuntu', sans-serif; }
		.attribute { vertical-align: top; }
		fieldset { border-color: var(--attrborder); padding-top: 3px; padding-bottom: 3px; padding-left: 6px; padding-right: 6px; }
		legend { font-weight: bold; }
		bottompad { padding-bottom: 15px; }
		nft_box { overflow: hidden; }
    </style>
	<script>
        document.addEventListener('DOMContentLoaded', function () {
            // Function to make API call and update HTML
            function fetchDataAndRender() {
                const apiUrl = 'https://api.mintgarden.io/collections/$collection_id';

                // Make the API call
                fetch(apiUrl)
                    .then(response => response.json())
                    .then(data => {
                        // Extract desired fields from the JSON response
                        const volume = data.volume;
                        const tradeCount = data.trade_count;
                        const floorPrice = data.floor_price;
						const nftCount = data.nft_count;
						const attachedToDIDCount = data.attached_to_did_count;
						const collectorCount = data.collector_count;

                        // Update HTML with the values
						if (volume == null) {
							document.getElementById('volumeValue').innerText = '';
						} else {
	                        document.getElementById('volumeValue').innerText = volume.toFixed(2);
						}
						if (tradeCount == null) {
							document.getElementById('tradeCountValue').innerText = '';
						} else {
	                        document.getElementById('tradeCountValue').innerText = tradeCount;
						}
						if (floorPrice == null) {
							document.getElementById('floorPriceValue').innerText = '';
						} else {
	                        document.getElementById('floorPriceValue').innerText = floorPrice;
						}
						if (nftCount == null) {
							document.getElementById('nftCount').innerText = '';
						} else {
							document.getElementById('nftCount').innerText = nftCount;
						}
						if (attachedToDIDCount == null) {
							document.getElementById('attachedToDIDCount').innerText = '';
						} else {
							document.getElementById('attachedToDIDCount').innerText = attachedToDIDCount;
						}
						if (collectorCount == null) {
							document.getElementById('collectorCount').innerText = '';
						} else {
							document.getElementById('collectorCount').innerText = collectorCount;
						}
                    })
                    .catch(error => console.error('Error fetching data:', error));
            }

            // Call the function when the DOM is loaded
            fetchDataAndRender();
        });
   </script>
</head>
<body>
    <img id="banner" src="$banner_file" alt="Banner">
	<div>
		<!-- #COLLECTION DETAILS  -->
		<div id="creator">
			<table class='data'>
			<tr><th colspan=4><img class="icon" src="$icon_file" alt="Icon"></th></tr>

			<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->

			<tr><td colspan=4><span class="h3" id="galleryTitle">$collection_name</span><br></td></tr>
			<tr><td colspan=4><span class="h5" id="galleryDesc">$description</span></td></tr>
			<tr><td colspan=4><span class="h6"><span id="collectionID" title="$collection_id">📋$collection_id</span></td></tr>

			<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->

			<tr><td colspan=4 id='creator_title' class='h5'>Creator</td></tr>
			<tr><td colspan=4><span id="creator_did" title="$creator_did">📋$creator_did_short</span></td></tr>
			<tr><td>👤 Name:</td><td colspan=3><span id="creator_name">$creator_name</span></td></tr>
			<tr><td>📄 Bio:</td><td colspan=3><span id="creator_bio">$creator_bio</span></td></tr>
			<tr><td>🌐 Website</td><td colspan=3><span id="creator_website"><a href="$creator_website" target="_blank">$creator_website</a></span></td></tr>
			<tr><td>❎ Twitter:</td><td colspan=3><span id="creator_twitter"><a href="https://x.com/$creator_twitter" target="_blank">@$creator_twitter</a></span></td></tr>

			<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->

			<tr><td colspan=4 id='collection_stats_title' class='h5'>Collection Stats</td></tr>
			<tr>	<td>📊 Volume:</td><td><span id="volumeValue"></span></td>
					<td>🧮 Trade Count:</td><td><span id="tradeCountValue"></span></td></tr>
			<tr>	<td>💲 Floor Price:</td><td><span id="floorPriceValue"></span></td>
					<td>🖼️ NFT Count:</td><td><span id="nftCount"></span></td></tr>
			<tr>	<td>👑 Attached to DID:</td><td><span id="attachedToDIDCount"></span></td>
					<td>💎 Collector Count:</td><td><span id="collectorCount"></span></td></tr>

			<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->

			<tr><td colspan=4>
				<a href='https://mintgarden.io/collections/$collection_id' target='_blank'>🌿 Mintgarden</a> &nbsp;&nbsp;&nbsp;&nbsp;
				<a href='https://spacescan.io/collection/$collection_id' target='_blank'>🛸 Spacescan</a></span> &nbsp;&nbsp;&nbsp;&nbsp;
				<a href='https://dexie.space/offers/$collection_id/XCH' target='_blank'>🦆 Dexie</a></span>
			</td></tr>

			<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->

			</table>
		</div>
	</div>
    <div class="gallery">

EOF

# get a list of the NFTs from the Mintgarden API
nft_list=$(curl -s https://api.mintgarden.io/collections/$collection_id/nfts/ids | jq -r '.[] | .encoded_id')
mg_nfts_json=""
for nid in $nft_list; do
	nft_data=$(curl -s https://api.mintgarden.io/nfts/$nid)
	mg_nfts_json="$mg_nfts_json$nft_data,"
done
# do a little mending of the JSON removing the last unneeded comma and wrap in square brackets so it's valid JSON.
mg_nfts_json="[${mg_nfts_json%?}]"

c=1
for item in $md_list; do
	detail_html=""

	# get data from the actual metadata file
	nft_description=""
	nft_data=$(cat "$working_folder/metadata/$item" | jq .)
	nft_name=$(echo $nft_data | jq '.name' | cut --fields 2 --delimiter=\")
	nft_description=$(echo $nft_data | jq '.description' | cut --fields 2 --delimiter=\")
	nft_format=$(echo $nft_data | jq '.format' | cut --fields 2 --delimiter=\")
	nft_sensitive=$(echo $nft_data | jq '.sensitive_content')
	nft_mint_tool=$(echo $nft_data | jq '.minting_tool' | cut --fields 2 --delimiter=\")
	nft_attributes=$(echo $nft_data | jq '.attributes')

	attr_html=""
	while IFS= read -r attr; do
	    att_type=$(echo "$attr" | jq -r '.trait_type')
	    att_value=$(echo "$attr" | jq -r '.value')
	    attr_html="$attr_html<tr><td class='attribute'>$att_type</td><td class='attribute'>$att_value</td></tr>"
	done < <(echo "$nft_attributes" | jq -c '.[]')

	# find the nftid from mintgarden
	nft_data=$(echo "$mg_nfts_json" | jq -r --arg name "$nft_name" '.[] | select(.data.metadata_json.name == $name)')
	nft_id=$(echo "$nft_data" | jq -r '.encoded_id')
	open_rarity_rank=$(echo $nft_data | jq -r '.openrarity_rank' | sed 's/null//g')
	xch_price=$(echo $nft_data | jq -r '.xch_price' | sed 's/null//g')
	owner_address=$(echo $nft_data | jq -r '.owner_address.encoded_id' | sed 's/null//g')
	owner_did=$(echo $nft_data | jq -r '.owner.encoded_id' | sed 's/null//g')
	owner_name=$(echo $nft_data | jq -r '.owner.name' | sed 's/null//g')
	minted_at=$(echo $nft_data | jq -r --arg type "0" '.events[] | select(.type == ($type | tonumber)) | .timestamp' | sed 's/null//g' | xargs -I {} date -d "{}" '+%Y-%m-%d %H:%M:%S %Z')
	royalty_percentage=$(echo $nft_data | jq -r '.royalty_percentage' | sed 's/null//g')
	royalty_address=$(echo $nft_data | jq -r '.royalty_address' | sed 's/null//g')

	echo "<div class='nft_box'>" >> "$output_html"
	imgfilename="${item%.*}"
	for ext in png jpg gif; do
		full_path="$working_folder/images/${imgfilename}.${ext}"
		if [ -e "$full_path" ]; then
			# ---- NFT DETAILS ----
			detail_html="$detail_html<tr><td colspan=2 class='nftid'><span class='nftid_icon' id='nft_id_$c' title='$nft_id'>🆔</span> <span id='nft_description'>$nft_description</span></td></tr>"
			detail_html="$detail_html<tr><td colspan=2 class='minted_at'>Minted: $minted_at</td></tr>"

			detail_html="$detail_html<tr><td colspan=2><hr></td></tr>"
			detail_html="$detail_html<tr><td colspan=2 class='nft'>Attributes:</td></tr>"
			detail_html="$detail_html<tr><td colspan=2><table class='nft'>$attr_html</table></td></tr>"

			detail_html="$detail_html<tr><td colspan=2><hr></td></tr>"
			detail_html="$detail_html<tr><td class='nft'>Format:</td><td><span id='nft_format' class='nft'>$nft_format</span></td></tr>"
			detail_html="$detail_html<tr><td class='nft'>Sensitive:</td><td><span id='nft_sensitive' class='nft'>$nft_sensitive</span></td></tr>"
			detail_html="$detail_html<tr><td class='nft'>Mint Tool:</td><td><span id='nft_mint_tool' class='nft'>$nft_mint_tool</span></td></tr>"
			detail_html="$detail_html<tr><td class='nft'>Open Rarity:</td><td id='open_rarity_rank'>$open_rarity_rank</td></tr>"

			detail_html="$detail_html<tr><td colspan=2><hr></td></tr>"
			detail_html="$detail_html<tr><td colspan=2 class='nft'>Owner: <span id='owner_name' title='$owner_name'>$owner_name</span> <span class='owner_did' id='owner_did_$c' title='$owner_did'>📛 </span> <span class='owner_address' id='owner_address_$c' title='$owner_address'>💼 </span></td></tr>"
			detail_html="$detail_html<tr><td class='nft'>Price:</td><td class='nft' id='xch_price'>$xch_price</td></tr>"

			detail_html="$detail_html<tr><td colspan=2><hr></td></tr>"
			detail_html="$detail_html<tr><td colspan=2 class='nft'><a href='images/$(basename $full_path)' target='_blank' title='Image File'>🖼️</a> <a href='metadata/$item' target='_blank' title='Metadata File'>Ⓜ️</a> <a href='$license_file' target='_blank' title='License File'>📜️</a></td></tr>"

			echo "<fieldset>" >> "$output_html"
			echo "<a href='images/$(basename $full_path)' target='_blank'><img src='images/$(basename $full_path)' alt='$(basename $full_path)'></a>" >> "$output_html"
			echo "<p><table>$detail_html</table></p><legend>$nft_name</legend></fieldset>" >> "$output_html"

			echo "<script>" >> "$output_html"
			echo "document.addEventListener('DOMContentLoaded', function () {" >> "$output_html"
			echo "	function fetchDataAndRender_$c() {" >> "$output_html"
			echo "		const apiUrl = 'https://api.mintgarden.io/nfts/$nft_id';" >> "$output_html"
			echo "		fetch(apiUrl)" >> "$output_html"
			echo "			.then(response => response.json())" >> "$output_html"
			echo "			.then(data => {" >> "$output_html"
			echo "				const ownerName = .owner.name;" >> "$output_html"
			echo "				const ownerDID = .owner.encoded_id;" >> "$output_html"
			echo "				const ownerWallet = .owner_address.encoded_id;" >> "$output_html"
			echo "				const nftPrice = .xch_price;" >> "$output_html"
			echo "				if (ownerName == null) {" >> "$output_html"
			echo "					document.getElementById('ownerName').innerText = '';" >> "$output_html"
			echo "				} else {" >> "$output_html"
			echo "					document.getElementById('ownerName').innerText = ownerName;" >> "$output_html"
			echo "				}" >> "$output_html"
			echo "				if (ownerDID == null) {" >> "$output_html"
			echo "					document.getElementById('ownerDID').innerText = '';" >> "$output_html"
			echo "				} else {" >> "$output_html"
			echo "					document.getElementById('ownerDID').innerText = ownerDID;" >> "$output_html"
			echo "				}" >> "$output_html"
			echo "				if (ownerWallet == null) {" >> "$output_html"
			echo "					document.getElementById('ownerWallet').innerText = '';" >> "$output_html"
			echo "				} else {" >> "$output_html"
			echo "					document.getElementById('ownerWallet').innerText = ownerWallet;" >> "$output_html"
			echo "				}" >> "$output_html"
			echo "				if (nftPrice == null) {" >> "$output_html"
			echo "					document.getElementById('nftPrice').innerText = '';" >> "$output_html"
			echo "				} else {" >> "$output_html"
			echo "					document.getElementById('nftPrice').innerText = nftPrice;" >> "$output_html"
			echo "				}" >> "$output_html"
			echo "			})" >> "$output_html"
			echo "			.catch(error => console.error('Error fetching data:', error));" >> "$output_html"
			echo "	}" >> "$output_html"
			echo "	fetchDataAndRender_$c();" >> "$output_html"
			echo "});" >> "$output_html"
			echo "</script>" >> "$output_html"

			break
		fi
	done
	echo "</div>" >> "$output_html"
	
	((c++))

done

# wrap up
echo "    </div>" >> "$output_html"

echo "<script>" >> "$output_html"
for ((i=1; i<c; i++)); do
	# Need to add a custom event listener for each NFT
	echo "document.addEventListener('DOMContentLoaded', function () {" >> "$output_html"
	echo "	var textToCopyElement = document.getElementById('nft_id_$i');" >> "$output_html"
	echo "	textToCopyElement.addEventListener('click', function () {" >> "$output_html"
	echo "		var titleToCopy = textToCopyElement.getAttribute('title');" >> "$output_html"
	echo "		var originalText = textToCopyElement.innerText || textToCopyElement.textContent;" >> "$output_html"
	echo "		var textarea = document.createElement('textarea');" >> "$output_html"
	echo "		textarea.value = titleToCopy;" >> "$output_html"
	echo "		document.body.appendChild(textarea);" >> "$output_html"
	echo "		textarea.select();" >> "$output_html"
	echo "		document.execCommand('copy');" >> "$output_html"
	echo "		document.body.removeChild(textarea);" >> "$output_html"
	echo "		textToCopyElement.classList.add('copied');" >> "$output_html"
	echo "		textToCopyElement.textContent = 'Copied!';" >> "$output_html"
	echo "		setTimeout(function () {" >> "$output_html"
	echo "			textToCopyElement.classList.remove('copied');" >> "$output_html"
	echo "			textToCopyElement.textContent = originalText;" >> "$output_html"
	echo "		}, 2000);" >> "$output_html"
	echo "	});" >> "$output_html"
	echo "});" >> "$output_html"
	echo "document.addEventListener('DOMContentLoaded', function () {" >> "$output_html"
	echo "	var textToCopyElement = document.getElementById('owner_did_$i');" >> "$output_html"
	echo "	textToCopyElement.addEventListener('click', function () {" >> "$output_html"
	echo "		var titleToCopy = textToCopyElement.getAttribute('title');" >> "$output_html"
	echo "		var originalText = textToCopyElement.innerText || textToCopyElement.textContent;" >> "$output_html"
	echo "		var textarea = document.createElement('textarea');" >> "$output_html"
	echo "		textarea.value = titleToCopy;" >> "$output_html"
	echo "		document.body.appendChild(textarea);" >> "$output_html"
	echo "		textarea.select();" >> "$output_html"
	echo "		document.execCommand('copy');" >> "$output_html"
	echo "		document.body.removeChild(textarea);" >> "$output_html"
	echo "		textToCopyElement.classList.add('copied');" >> "$output_html"
	echo "		textToCopyElement.textContent = 'Copied!';" >> "$output_html"
	echo "		setTimeout(function () {" >> "$output_html"
	echo "			textToCopyElement.classList.remove('copied');" >> "$output_html"
	echo "			textToCopyElement.textContent = originalText;" >> "$output_html"
	echo "		}, 2000);" >> "$output_html"
	echo "	});" >> "$output_html"
	echo "});" >> "$output_html"
	echo "document.addEventListener('DOMContentLoaded', function () {" >> "$output_html"
	echo "	var textToCopyElement = document.getElementById('owner_address_$i');" >> "$output_html"
	echo "	textToCopyElement.addEventListener('click', function () {" >> "$output_html"
	echo "		var titleToCopy = textToCopyElement.getAttribute('title');" >> "$output_html"
	echo "		var originalText = textToCopyElement.innerText || textToCopyElement.textContent;" >> "$output_html"
	echo "		var textarea = document.createElement('textarea');" >> "$output_html"
	echo "		textarea.value = titleToCopy;" >> "$output_html"
	echo "		document.body.appendChild(textarea);" >> "$output_html"
	echo "		textarea.select();" >> "$output_html"
	echo "		document.execCommand('copy');" >> "$output_html"
	echo "		document.body.removeChild(textarea);" >> "$output_html"
	echo "		textToCopyElement.classList.add('copied');" >> "$output_html"
	echo "		textToCopyElement.textContent = 'Copied!';" >> "$output_html"
	echo "		setTimeout(function () {" >> "$output_html"
	echo "			textToCopyElement.classList.remove('copied');" >> "$output_html"
	echo "			textToCopyElement.textContent = originalText;" >> "$output_html"
	echo "		}, 2000);" >> "$output_html"
	echo "	});" >> "$output_html"
	echo "});" >> "$output_html"
done

cat <<EOF >> "$output_html"
	document.addEventListener('DOMContentLoaded', function () {

		var textToCopyElement = document.getElementById('creator_did');

		textToCopyElement.addEventListener('click', function () {

			var titleToCopy = textToCopyElement.getAttribute('title');
			var originalText = textToCopyElement.innerText || textToCopyElement.textContent;
			var textarea = document.createElement('textarea');
			textarea.value = titleToCopy;
			document.body.appendChild(textarea);
			textarea.select();
			document.execCommand('copy');
			document.body.removeChild(textarea);
			textToCopyElement.classList.add('copied');
			textToCopyElement.textContent = "Copied!";

			setTimeout(function () {
				textToCopyElement.classList.remove('copied');
				textToCopyElement.textContent = originalText;
			}, 2000);

		});
	});
	document.addEventListener('DOMContentLoaded', function () {

		var textToCopyElement = document.getElementById('collectionID');

		textToCopyElement.addEventListener('click', function () {

			var titleToCopy = textToCopyElement.getAttribute('title');
			var originalText = textToCopyElement.innerText || textToCopyElement.textContent;
			var textarea = document.createElement('textarea');
			textarea.value = titleToCopy;
			document.body.appendChild(textarea);
			textarea.select();
			document.execCommand('copy');
			document.body.removeChild(textarea);
			textToCopyElement.classList.add('copied');
			textToCopyElement.textContent = "Copied!";

			setTimeout(function () {
				textToCopyElement.classList.remove('copied');
				textToCopyElement.textContent = originalText;
			}, 2000);

		});
	});

	</script>
	<script src="https://code.jquery.com/jquery-3.3.1.slim.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js"></script>
EOF

echo "</body>" >> "$output_html"
echo "</html>" >> "$output_html"
echo "HMTL page generated: $output_html"

