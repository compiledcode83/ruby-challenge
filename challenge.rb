require 'json'

# Load the data from a JSON file.
def load_data(file_path)
  begin
    JSON.parse(File.read(file_path))
  rescue Errno::ENOENT
    puts "The file #{file_path} does not exist"
    exit
  rescue JSON::ParserError
    puts "There was an error parsing the JSON data in the file #{file_path}"
    exit
  end
end

# Connect user data to company data following the criteria.
def connect_data(user_data, company_data)
  company_data.map do |company|
    users = user_data.select do |user|
      user["company_id"] == company["id"] && user["active_status"] == true
    end
    users.each do |user|
      user["tokens"] += company["top_up"]
      user["email_sent"] = company["email_status"] && user["email_status"]
    end
    company["users"] = users.sort_by { |user| user["last_name"] }
    company
  end.sort_by { |company| company["id"] }
end

# Generate an output file following the given format.
def generate_output(output_file_path, data)
  begin
    File.open(output_file_path, 'w') do |file|
      data.each do |company|
        file.puts "Company Id: #{company["id"]}"
        file.puts "Company Name: #{company["name"]}"

        emailed_users = company["users"].select { |user| user["email_sent"] }
        non_emailed_users = company["users"].select { |user| !user["email_sent"] }
  
        process_users(file, "Users Emailed:", emailed_users, company)
        process_users(file, "Users Not Emailed:", non_emailed_users, company)
        
        file.puts "Total amount of top ups for #{company["name"]}: #{company["users"].inject(0) { |sum, user| sum + company["top_up"] }}\n\n"
      end
    end
  rescue IOError
    puts "There was an issue writing to the file #{output_file_path}"
  end
end

# Processes and writes user information to the output file
def process_users(file, header, users, company)
  unless users.empty?
    file.puts header
    users.each do |user|
      file.puts "    #{user["last_name"]}, #{user["first_name"]}, #{user["email"]}"
      file.puts "        Previous Token Balance, #{user["tokens"] - company["top_up"]}"
      file.puts "        New Token Balance #{user["tokens"]}"
    end
  end
end

# Load the data.
user_data = load_data('users.json')
company_data = load_data('companies.json')

# Process the data.
connected_data = connect_data(user_data, company_data)

# Generate the output.
generate_output('output.txt', connected_data)