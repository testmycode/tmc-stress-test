
module Paths
  extend Paths
  
  def root_path
    Pathname(__FILE__).expand_path.parent.parent.parent
  end
  
  def work_dir
    root_path + 'work'
  end
  
  def repo_dir
    work_dir + 'repo'
  end
  
  def local_exercise_dir
    work_dir + 'exercise'
  end
  
  def submission_zip_path
    work_dir + 'submission.zip'
  end
end
