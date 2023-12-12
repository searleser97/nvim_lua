use nvim_oxi as oxi;
use oxi::{Dictionary, Function};
use std::fs;
use std::time::SystemTime;
use std::cmp::Reverse;

// A function that returns the modified time of a file
fn modified_time(file: &fs::DirEntry) -> SystemTime {
    file.metadata().unwrap().modified().unwrap()
}

// A function that lists only files in a directory sorted by modified date
fn file_names_sorted_by_modified_date(dir: String) -> oxi::Result<Vec<String>> {
    // Get the files in the directory
    let files = fs::read_dir(dir).unwrap();
    // Collect them into a vector
    let mut files: Vec<_> = files.map(|f| f.unwrap()).collect();
    // Sort them by modified time
    files.sort_by_key(|f| Reverse(modified_time(f)));
    let file_paths: Vec<_> = files.iter()
        .filter(|f| f.file_type().unwrap().is_file())
        .map(|f| f.file_name().into_string().unwrap()).collect();
    Ok(file_paths)
}

#[oxi::module]
fn lua_utils() -> oxi::Result<Dictionary> {
    Ok(Dictionary::from_iter([
      (
        "file_names_sorted_by_modified_date",
        Function::from_fn(file_names_sorted_by_modified_date)
      )
    ]))
}

