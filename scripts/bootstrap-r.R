library_path <- commandArgs(trailingOnly = TRUE)[[1]]
.libPaths(c(library_path, .libPaths()))
for (package in c("IRkernel", "languageserver")) {
    if (!file.exists(file.path(library_path, package, "DESCRIPTION"))) {
        install.packages(package, lib = library_path, repos = "https://cloud.r-project.org")
    }
    if (!requireNamespace(package, lib.loc = library_path, quietly = TRUE)) {
        stop(paste(package, "installation failed in", library_path))
    }
}
IRkernel::installspec(user = TRUE, name = "nvim-r", displayname = "R (Neovim)")
