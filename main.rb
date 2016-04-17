# Script	basecampArchiver 
# Author	Marlise Briedenhann
# Date		15 April 2016
# History	

require "date"
require "stringio"
require "rubygems"
require "zip"
require "nokogiri"
require "json"

# Check if a directory exists
def directory_exists?(directory)
	File.directory?(directory)
end

def logmessage(message)
time = Time.new
time = time.strftime("%Y-%m-%d %H:%M:%S")

	puts "[" + time + "] " + message
end

def get_zip_file_paths(path)
	Dir.glob(path + '/**/*.zip').each do |f|
		yield f
	end
end

def get_zip_inner_file(zip_file, file)
	found = false
	Zip::InputStream.open(zip_file) do |io|
		while ((entry = io.get_next_entry) && !found)
			if (File.basename(entry.name) == file)
				found = true
				logmessage " ............ processing #{entry.name}'"
				@file_contents = io.read
				return @file_contents
			end
		end
	end
end

def archive_projects_to_file(filename, json_projects)
	File.open(filename, "w") do |f|
		f.write(json_projects)
	end 
end

archive_array = []

def add_item(id, title, url, archive_array)
	item = Hash[ "id" => id, "title" => title, "url" => url]
	archive_array << item 
	return item
end

logmessage " ... Running basecampArchiver v0.1"

# TODO: Get folder from user input
folder = "/Users/marlisebriedenhann/Repositories/BasecampArchiver/archives"

if directory_exists?(folder)
	# TODO: Iterate through each compressed folder
	Dir.chdir(folder) do
		logmessage " ... iterating through - " + Dir.pwd
		
		archives_to_process = []
		get_zip_file_paths(folder) {|f| archives_to_process << f}
		archives_length = archives_to_process.length.to_s
		archives_length == 1 	? (logmessage " ...... " + archives_length + " project to be archived.")
								: (logmessage " ...... " + archives_length + " projects to be archived.")
		
		# Use RubyZip to iterate through in memory zip file
		archives_to_process.each_with_index {|zip_file, index| logmessage(" ......... archive " + File.basename(zip_file)) 
			file_selected = get_zip_inner_file(zip_file, "index.html")
			
			doc = Nokogiri.HTML(file_selected)
			#title
			title = doc.at('title').text
			
			#url
			url = doc.xpath("//a[contains(text(), 'projects')]").text
			
			#projectid 
			projectid = url.scan(/projects\/\d*(?:\.\d+)?/).first.scan(/\d/).join
			
			logmessage " ............ [#{projectid}, #{title}, #{url}]"
			
			# add new item
			item = add_item(projectid, title, url, archive_array)
			if item.length > 0 	? (logmessage " ......... #{File.basename(zip_file)} archived.")
								: (logmessage " ......... #{File.basename(zip_file)} not archived.")
			end
			
			}
		end
		archive_projects_to_file("basecamp_project_archives.json", archive_array)
		logmessage " ... all basecamp projects archived to basecamp_project_archives.json."
	else
	logmessage " ... invalid folder, aborting basecampArchiver."
	end
logmessage " ... Completed."	
	