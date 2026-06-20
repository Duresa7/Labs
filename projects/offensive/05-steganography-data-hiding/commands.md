# Commands

## Install OpenStego on Kali

```bash
# Download openstego_0.8.6-1_all.deb from the releases page:
#   https://github.com/syvaidya/openstego/releases
sudo dpkg -i openstego_0.8.6-1_all.deb
openstego                 # launch the GUI
```

## Hide (GUI: Hide Data)

| Field | Value |
|---|---|
| Message file | the secret data file to embed |
| Cover file | an ordinary image to carry it |
| Output stego file | where to save the result |
| Encryption | AES128 + a password |

Then **Hide data** generates the stego image and shows a success message.

## Extract (GUI: Extract Data)

| Field | Value |
|---|---|
| Input stego file | the generated image |
| Output folder | where to write the recovered file |
| Password | the one set during hide |

Then **Extract data** recovers the original file. A wrong password fails on the AES layer.
