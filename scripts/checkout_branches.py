import argparse
import os 
import sh
import subprocess

def run(*args, **kwargs):
    subprocess.run(*args, shell=True, check=True, **kwargs)

parser = argparse.ArgumentParser(description="Checkout and update branches in project repos")

parser.add_argument("-f", "--force", action="store_true", help="Force rebuild and install", default=False)
parser.add_argument("--coreir", help="coreir and pycoreir branch", default="master")
parser.add_argument("--mapper", help="mapper branch", default="master")
parser.add_argument("--halide", help="halide branch", default="master")
parser.add_argument("--pnr-doctor", help="pnr branch", default="master")
parser.add_argument("--cgra-generator", help="generator branch", default="master")

args = parser.parse_args()

class Repo:
    def install(self):
        raise NotImplementedError()

    @property
    def directory(self):
        return type(self).__name__

    @property
    def branch(self):
        raise NotImplementedError()


class Halide_CoreIR(Repo):
    def install(self):
        pass

    @property
    def branch(self):
        return args.halide

class coreir(Repo):
    def install(self):
        run("make clean")
        run("sudo make -j 2 install")

    @property
    def branch(self):
        return args.coreir

class pycoreir(Repo):
    def install(self):
        run("pip install -e .")

    @property
    def branch(self):
        return args.coreir

class CGRAMapper(Repo):
    def install(self):
        run("make clean")
        run("sudo make -j 2 install")

    @property
    def branch(self):
        return args.mapper

class smt_pnr(Repo):
    @property
    def directory(self):
        return "smt-pnr"

    def install(self):
        run("pip install -e package")

    @property
    def branch(self):
        return args.pnr_doctor

class CGRAGenerator(Repo):
    @property
    def branch(self):
        return args.cgra_generator

    def install(self):
        pass

for repo in (Halide_CoreIR(), coreir(), pycoreir(), CGRAMapper(), smt_pnr(), CGRAGenerator()):
    branch = "master"
    print(type(repo).__name__)
    print("=" * len(type(repo).__name__))
    os.chdir(repo.directory)
    current_head = sh.git("symbolic-ref", "HEAD").rstrip()
    print(f"    Currently on branch {current_head}")
    if current_head != f"refs/heads/{branch}" or args.force:
        sh.git.pull()
        print(f"    Checking out {branch}")
        sh.git.checkout(branch)
        print("    Installing")
        repo.install()
    print()
    os.chdir("..")
