require_relative 'utils'

module CocoapodsPruneLocalizations
  class Pruner
    def initialize(context, user_options)
      @sandbox_root = Pathname.new context.sandbox_root
      @pod_project = Xcodeproj::Project.open File.join(context.sandbox_root, 'Pods.xcodeproj')
      @user_options = self.class.user_options(context, user_options)
      @pruned_bundles_path = File.join(context.sandbox_root, "Pruned Localized Bundles")
      FileUtils.mkdir @pruned_bundles_path unless Dir.exist? @pruned_bundles_path
    end
    
    def self.user_options(context, orig_user_opts = {})
      user_options = {}
      if orig_user_opts["localizations"]
        user_options["localizations"] = orig_user_opts["localizations"].map do |loc|
          loc = loc + ".lproj" unless loc.end_with? ".lproj"
          loc
        end
      else
        user_options["localizations"] = Utils.user_project_localizations(context.umbrella_targets)
      end
      user_options
    end

    def resources_scripts(group)
      file_references = []
      group.children.objects.each do |children|
        if children.class == Xcodeproj::Project::Object::PBXFileReference && children.path.end_with?("resources.sh")
            file_references << children
        elsif children.class == Xcodeproj::Project::Object::PBXGroup
            file_references.concat(self.resources_scripts(children))
        end
      end
      file_references
    end
    
    def prune!
      rsrc_scripts_files = Hash.new
      self.resources_scripts(@pod_project["Targets Support Files"]).each do |file|
        rsrc_scripts_files[file] = File.readlines(file.real_path)
      end
      
      langs_to_keep = @user_options["localizations"] || []
      Pod::UI.title 'Pruning unused localizations' do

        #Group all the Pods
        pod_groups = []
        pod_items = @pod_project["Pods"]
        dev_pod_items = @pod_project["Development Pods"]
        pod_groups += pod_items.children.objects if pod_items
        pod_groups += dev_pod_items.children.objects if dev_pod_items

        pod_groups.each do |group|

          #Gather all Resources groups
          resGroups = group.recursive_children_groups.select do |group|
            group.name == "Resources"
          end
          next unless resGroups.length > 0
          
          markForRemoval = []
          trimmedBundlesToAdd = Hash.new

          resGroups.each do |resGroup|
            subTrimmedBundlesToAdd = Hash.new
            resGroup.files.each do |file|
              keep = true
              if file.path.end_with? ".lproj"
                keep = langs_to_keep.include?(File.basename(file.path))
              elsif file.path.end_with? ".bundle"
                trimmed_bundle = self.trimmed_bundle(file.real_path)
                if trimmed_bundle 
                  subTrimmedBundlesToAdd[file.real_path] = [trimmed_bundle, file]
                  keep = true
                end
              end
              if !keep
                markForRemoval << file
              end
            end
            trimmedBundlesToAdd[resGroup] = subTrimmedBundlesToAdd unless subTrimmedBundlesToAdd.length == 0              
          end

          #Remove file references indentified for removal
          if markForRemoval.length > 0
            Pod::UI.section "Pruning in #{group.path}" do
              markForRemoval.each do |file|
                Pod::UI.message "- Pruning #{file}"
                
                relative_path = file.real_path.relative_path_from @sandbox_root
                rsrc_scripts_files.each_value do |lines|
                  for i in 0...lines.length
                    line = lines[i]
                    if line.include?(relative_path.to_s)
                      lines[i] = ""
                    end
                  end
                end
                file.remove_from_project
              end
            end
          end

          if trimmedBundlesToAdd.length > 0
            Pod::UI.section "Adding trimmed bundles to #{group.path}" do
              group_path = File.join(@pruned_bundles_path, group.path)
              FileUtils.mkdir group_path unless Dir.exist? group_path
              trimmedBundlesToAdd.each_pair do |resGroup, bundleArray|
                bundleArray.each_pair do |original_bundle_path, bundle_arr|
                  bundle_path = bundle_arr[0]
                  original_file = bundle_arr[1]
                  bundle_name = File.basename(original_bundle_path)
                  new_bundle_path = File.join(group_path, bundle_name)
                  FileUtils.rm_r(new_bundle_path) if File.exist? new_bundle_path
                  FileUtils.mv(bundle_path, new_bundle_path)
                  # Update Project path
                  original_file.set_path(new_bundle_path)

                  # Update Resource Scripts path
                  relative_path = original_bundle_path.relative_path_from(@sandbox_root).to_s
                  new_relative_path = Pathname.new(new_bundle_path).relative_path_from(@sandbox_root).to_s
                  rsrc_scripts_files.each_value do |lines|
                    for i in 0...lines.length
                      lines[i] = lines[i].gsub(relative_path, new_relative_path)
                    end
                  end
                end
              end
            end
          end
          
        end
        
        rsrc_scripts_files.each_pair do |file, lines|
          fd = File.open(file.real_path, "w")
          lines.each do |line|
            fd.puts line unless (line == "") 
          end
          fd.close
        end
        @pod_project.save
      end
    end
    
    def trimmed_bundle(bundle_path)
      langs_to_keep = @user_options["localizations"] || []
      return unless Dir.exist? bundle_path
      tmp_dir = Dir.mktmpdir
      changed_bundle = false
      Dir.foreach(bundle_path) do |file_name|
        if (file_name == "." || file_name == "..") 
          next
        end
        
        absolute_file_path = File.join(bundle_path, file_name)
        if file_name.end_with? ".lproj"
          if langs_to_keep.include?(file_name)
            FileUtils.cp_r(absolute_file_path, tmp_dir)
          else
            changed_bundle = true
          end
        elsif file_name.end_with? ".bundle"
          sub_trimmed_bundle = self.trimmed_bundle(absolute_file_path)
          if sub_trimmed_bundle
            sub_bundle_path = File.join(tmp_dir, file_name)
            FileUtils.mv(sub_trimmed_bundle, sub_bundle_path)
            changed_bundle = true
          else
            FileUtils.cp_r(absolute_file_path, tmp_dir)
          end
        else
          FileUtils.cp_r(absolute_file_path, tmp_dir)
        end
      end
      
      tmp_dir if changed_bundle
    end
  end
end