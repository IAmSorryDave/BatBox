
from pathlib import Path
from semver.version import Version

class VersionFileManager(Version):

  """
  A subclass of Version which creates a VERSION file if none exists then parses the file.
  """
  
  version_filename: str = "VERSION"
  version_filename_encoding: str = "utf-8"
  semantic_version_starting_label: str = "0.0.0"

  @property
  def update_version_file(self) -> None:
    self.write_version_file(version_filepath=self.version_filepath, semantic_version_label=str(self), encoding=self.version_filename_encoding)

  @property
  def bump_major(self) -> None:
    super().bump_major()
    self.update_version_file

  @property
  def bump_minor(self) -> None:
    super().bump_minor()
    self.update_version_file

  @property
  def bump_patch(self) -> None:
    super().bump_patch()
    self.update_version_file

  @property
  def bump_prerelease(self) -> None:
    super().bump_prerelease()
    self.update_version_file
  
  @property
  def bump_build(self) -> None:
    super().bump_build()
    self.update_version_file

  @staticmethod
  def read_and_validate_version_file(version_filepath: Path, *args, **kwargs) -> Version:
    
    version_label = open(version_filepath,"r").read().strip()

    assert super().is_valid(version_label), f"{str(version_filepath)} file contains invalid semantic version format."
      
    return super().parse(version_label, *args, **kwargs)

  @classmethod
  def initialize_version_file(cls, version_filepath: Path, semantic_version_starting_label: str = "0.0.0", version_filename_encoding: str = "utf-8", *args, **kwargs) -> Version:

    cls.write_version_file(version_filepath=version_filepath, semantic_version_label=semantic_version_starting_label, encoding=version_filename_encoding)
    
    return super().parse(semantic_version_starting_label, *args, **kwargs)
    
  @staticmethod
  def write_version_file(version_filepath: Path, semantic_version_label: str, encoding: str = "utf-8") -> None:
    with version_filepath.open("w", encoding=encoding) as f:
      f.write(semantic_version_label)
  
  @classmethod
  def parse(cls, alternate_version_filename: str | None = None, *args, **kwargs):

    """
    Parse a version file. If none found initializes new version file.

    :param version_filename: Alternate Filename 
    :return: a new instance
    """

    if alternate_version_filename:
      version_filepath: Path = Path(alternate_version_filename).resolve()
    else:
      version_filepath: Path = Path(cls.version_filename).resolve()
      
    if version_filepath.exists():
      version_instance = cls.read_and_validate_version_file(version_filepath, *args, **kwargs)
    else:
      version_instance = cls.initialize_version_file(version_filepath, semantic_version_starting_label=cls.semantic_version_starting_label, version_filename_encoding=cls.version_filename_encoding, *args, **kwargs)

    if alternate_version_filename:
      version_instance.version_filename = alternate_version_filename

    version_instance.version_filepath = version_filepath

    return version_instance

  
        
