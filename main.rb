require 'csv'

files = ['./Lead.csv', './Contact.csv']

class Contact
	attr_accessor :entity_type, :record

	def initialize(r, file)
		file == './Lead.csv' ? @entity_type = 'lead' : @entity_type = 'contact'
		# sf gives mailing addresses to contacts, not leads; merging them back together
		if @entity_type == 'contact'
			if r[:street].nil? and r[:city].nil? and r[:state].nil? and r[:postalcode].nil?
				r[:street] = r[:mailingstreet]
				r[:city] = r[:mailingcity]	
				r[:state] = r[:mailingstate]	
				r[:postalcode] = r[:mailingpostalcode]	
				r[:country] = r[:mailingcountry]	
			else
				r[:otherstreet] = r[:mailingstreet]
				r[:othercity] = r[:mailingcity]	
				r[:otherstate] = r[:mailingstate]	
				r[:otherpostalcode] = r[:mailingpostalcode]	
				r[:othercountry] = r[:mailingcountry]	
			end
		end
		@record = r
	end

	def self.get_cols(contacts)
		blacklist = [	
			:mailingstreet, :mailingcity, :mailingstate, :mailingpostalcode, :mailingcountry, # because of merge in init
			:mailingstatecode, :mailingcountrycode, :statecode, :countrycode, :othercountrycode, :otherstatecode,
			:billingstatecode, :billingcountrycode, :shippingstatecode, :shippingcountrycode
		]
		lead_cols = contacts.select { |c| c.entity_type == 'lead' }.first.record.headers - blacklist
		contact_cols = contacts.select { |c| c.entity_type == 'contact' }.first.record.headers - blacklist
		return (lead_cols + contact_cols).uniq
	end
end

# creating array of Contact objects from Contact and Lead files -- ignoring converted leads
contacts = Array.new
files.each do |file|
	CSV.foreach(File.path(file), headers: true, header_converters: :symbol, encoding: 'ISO-8859-1:UTF-8') do |row|
		c = Contact.new(row, file)
		contacts.push(c) unless c.record[:isconverted].to_i == 1 && c.entity_type == 'lead'
	end
end

# merging in account data
CSV.foreach(File.path('./Account.csv'), headers: true, header_converters: :symbol, encoding: 'ISO-8859-1:UTF-8') do |row|
	contacts.select { |c| c.record[:accountid] == row[:id] }.each do |c|
		row.each do |col,val|
			# overriding a few duplicate column names to prevent losing data
			col = :accountid if	col == :id 
			col = :accounttype if col == :type
			col = :accountcreateddate if col == :createddate
			col = :accountname if col == :name
			c.record[col] = val 
		end
	end
end

columns = Contact.get_cols(contacts)
puts columns;
new_csv = CSV.open('./merged_data.csv', 'w', write_headers: true, headers: columns.push('entitytype'))
contacts.each do |c|
	row = Hash.new
	row['entitytype'] = c.entity_type
	columns.each do |col|
		row[col] = c.record[col] unless c.record[col].nil? || c.record[col] == '[not provided]'
	end
	new_csv << row
end


