fn main() {
  println!("cargo:rustc-link-search=E:\\forks\\luajit\\src");
  println!("cargo:rustc-link-lib=lua51");
  println!("cargo:rustc-link-lib=luajit");
}
