task :importTrees => :environment do
	rows = CSV.read(Rails.root + "app/assets/data/formdata.csv")
	#header = rows.first.map{|c| c.downcase }
    rows = rows[1..-1]
    rows.each do |row|
	    address = row[21].to_s.strip + ", "
	    if row[22].present?
	     address = address + row[22].to_s.strip + ", "
	    end
	    address = address + row[23].to_s.strip + ", " + row[24].to_s.strip + ", " + row[25].to_s.strip + ", " + row[26].to_s.strip
	    existing_user = User.where(address: address).first

	    # then we have owner information and id

	    if existing_user.present?
	    # get that user_id, store it for now
	    	user_id1 = existing_user.id
	    end

	    ladder = "yes" if row[29].to_s.strip == "Yes, I have a ladder."
	    ladder = "no" if row[29].to_s.strip == "I won't be able to get a ladder."
	    ladder = "borrow" if row[29].to_s.strip == "I can borrow a ladder from a friend or neighbour."
	    keep = "yes" if row[74].to_s.strip == "Yes, please!"
	    keep = "no" if row[74].to_s.strip == "No, thanks."
	    keep = "abit" if row[74].to_s.strip == "Yes, but less than 1/3 is more than enough."
	    u = User.new
	    u.fname = row[7]
	    u.lname = row[8]
	    u.email = row[9]
	    u.email = (User.last.id + 1).to_s + "@example.com" if u.email.blank?
	    u.created_at = row[84]
	    u.updated_at = row[86]
	    u.snail_mail = row[5].to_s.strip != "Do not mail"
	    u.password = Devise.friendly_token.first(8)
	    u.phone = row[10].to_s
	    if row[11].present? && row[11].to_i != 0
	    	u.phone = "Day: " + u.phone + " - Evening: " + row[11].to_s
	    end
		   
	    # the last user was a submitter, must create owner, add address to this
	    if row[15].present? && existing_user.blank?
	    	u.skip_confirmation!
	    	u.save
	    	 puts "submitter"
	    	 puts u.errors.full_messages
	    	 puts u.to_yaml
		    u2 = User.new
		    u2.created_at = row[84]
	    	u2.updated_at = row[86]
		    u2.fname = row[15]
		    u2.lname = row[16]
		    u2.email = row[19]
		    u2.email = (User.last.id + 1).to_s + "@example.com" if u2.email.blank?
		    u2.phone = row[17].to_s
		    u2.snail_mail = row[5].to_s.strip != "Do not mail"
		    u2.contactnotes = row[20].to_s.strip if row[20].present?
		    u2.password = Devise.friendly_token.first(8)
		    if row[18].present? && row[18].to_i != 0
		    	u2.phone += " - " + row[18].to_s
		    end
		    u2.address = address
		    u2.ladder = ladder
		    u2.propertynotes = ""
		    u2.propertynotes = row[75] if row[75].present?
		    u2.propertynotes += "\n" + row[76] if row[76].present?
		    u2.home_ward = row[27]
		    u2.skip_confirmation!
		    u2.save
		     puts "owner"
		     puts u2.errors.full_messages
			 puts u2.to_yaml
		    user_id2 = u2.id
		elsif row[15].present? && existing_user.present?
		# the last user was a submitter, must use queried user as owner_id
			user_id2 = existing_user.id
			 puts "exists"
			 puts u.errors.full_messages
			 puts existing_user.to_yaml
	    elsif row[15].blank? && existing_user.blank?
	    # the last user was an owner, add address, that's it
		    u.address = address
		    u.propertynotes = ""
		    u.propertynotes = row[75] if row[75].present?
		    u.propertynotes += "\n" + row[76] if row[76].present?
		    u.ladder = ladder
		    u.home_ward = row[27]
		    u.skip_confirmation!
			u.save
			 puts "just new owner"
			 puts u.errors.full_messages
			 puts u.to_yaml
			user_id1 = u.id    
	    end
	    extranotes = ""
	    extranotes += row[1].to_s.strip if row[1].present?
	    extranotes += "\n" + row[2].to_s.strip	if row[2].present?
	    # Trees
	    g = 7
	    for i in 0..5
	    	gap = g*i
	    	if row[31+gap].present? || row[32+gap].present? 
	    		notes = ""
	    		t = Tree.new
	    		t.treatment = row[73].to_s if row[73].present?
	    		if user_id2.present?
	    			t.owner_id = user_id2
	    			t.submitter_id = user_id1
	  			else
	  				t.owner_id = user_id1
	    		end
	    		if row[31+gap].present? && row[31+gap].to_s != "Other (specify below)"
	    			t.species = row[31+gap].to_s.strip
	    		elsif row[32+gap].present? 
					t.species = row[32+gap].to_s.strip
	    		end
	    		t.keep = keep
	    		t.subspecies = row[33+gap].to_s if row[33+gap].present?
	    		t.ripen = row[34+gap].to_s.strip if row[34+gap].present?
	    		if row[35+gap].present?	   
	    			if row[35+gap] == "> 3 storeys (> 9 metres, 30 feet)"	
	    				t.height = ">3" 	    			    			
	    			elsif row[35+gap] == "2-3 storeys (20-30 feet, 6-9 metres)"
	    				t.height = "2-3" 	    				
	    			elsif row[35+gap] == "1 - 2 storeys (10-20 feet, 3-6 metres)" 		
	    				t.height = "1-2" 
	    			elsif row[35+gap] == "< 1 storey (< 10 feet, 3 metres)" 		
	    				t.height = "<1" 
	    			end
	    		end	
	  			t.pickable = true
	     		t.pickable = false if row[36+gap].present?
	     		notes += "\nNot Pickable because:" +  row[36+gap].to_s if row[36+gap].present?	    			
	    		notes += "\n" + row[37+gap].to_s.strip if row[37+gap].present?

	    		if notes.present? || extranotes.present?
	    			t.additional = ""
	    			t.additional += notes if notes.present?
	    			t.additional += extranotes if extranotes.present?
	    		end
	    		t.save
	    		puts t.to_yaml
	    		puts t.errors.full_messages

	    	end

	    end



    end
end
