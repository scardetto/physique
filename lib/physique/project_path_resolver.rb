require 'albacore/project'

module Physique
  module ProjectPathResolver
    extend self

    DEFAULT_PROJECT_FOLDER = 'src'

    @@project_folder = DEFAULT_PROJECT_FOLDER

    def project_dir
      @@project_folder
    end

    def project_dir=(val)
      @@project_folder = val
    end

    def resolve(name, ext = 'cs')
      return name if is_full_path name
      "#{@@project_folder}/#{name}/#{name}.#{ext}proj"
    end

    private

    def is_full_path(name)
      name =~ /^.*\.(cs|fs|vb)proj$/i
    end
  end
end

module Albacore
  class Project
    def add_compile_node(folder, name)
      if folder == :root
        add_include :Compile, "#{name}"
      else
        add_include :Compile, "#{folder.to_s}\\#{name}"
      end
    end

    def add_include(type, value)
      @proj_xml_node.xpath("//xmlns:ItemGroup[xmlns:#{type.to_s}]").first << "<#{type.to_s} Include=\"#{value}\" />"
    end
  end
end