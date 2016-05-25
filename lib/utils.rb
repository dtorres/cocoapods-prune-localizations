module CocoapodsPruneLocalizations
  class Utils
    def self.user_project_localizations(targets)
      localizations = []
      user_projects = targets.map { |target| target.user_project_path }
      user_projects.uniq!.compact!
      
      user_projects.each do |project_path|
        project = Xcodeproj::Project.open project_path
        project.files.each do |file_ref|
          if file_ref.path.include? ".lproj"
            localizations << File.dirname(file_ref.path)
          end
        end
      end
      
      localizations.uniq!
      localizations
    end
  end
end