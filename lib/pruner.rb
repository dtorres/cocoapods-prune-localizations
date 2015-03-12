module CocoapodsPruneLocalizations
  class Pruner
    def initialize(context, user_options)
      @pod_project = Xcodeproj::Project.open File.join(context.sandbox_root, 'Pods.xcodeproj')
      @user_options = user_options
    end
    
    def prune!
      langs_to_keep = @user_options["localizations"] || []
      Pod::UI.section 'Pruning unused localizations' do
        pod_groups = @pod_project["Pods"].children.objects
        dev_pod_group = @pod_project["Development Pods"]
        pod_groups += dev_pod_group.children.objects if dev_pod_group
        pod_groups.each do |group|
          resGroup = group["Resources"]
          next unless resGroup
          
          markForRemoval = []
          trimmedBundlesToAdd = []
          resGroup.files.each do |file|
            keep = true
            if file.name.end_with? ".lproj"
              keep = langs_to_keep.include?(file.name)
            elsif file.path.end_with? ".bundle"
              Pod::UI.warn "[#{group.path}] Unprocessed bundle #{file.name}"
            end
            if !keep
              markForRemoval << file
            end
          end
          
          if markForRemoval.length > 0
            Pod::UI.section "Pruning in #{group.path}" do
              markForRemoval.each do |file|
                file.remove_from_project
              end
            end
          end
          
        end
        @pod_project.save
      end
    end
    
  end
end