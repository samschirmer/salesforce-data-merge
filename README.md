Usage:

1) Place script in a folder with Account.csv, Contact.csv, and Lead.csv exports from Salesforce.
2) Delete any columns from the files you don't want. You can also blacklist them by modifying the script.
3) Run the script.

The script will ignore leads that have been converted to contacts, remove redundant data between spreadsheets (based on column name), drop state/country code columns, move contact "mailing" addresses into either the standard "street/city/state" or "other" address columns (from the lead.csv), and merge the account metadata onto the contact records. The whole thing gets dumped into a single CSV file for easier importing into whatever you want. 

TODO:

- merge in opportunity data

