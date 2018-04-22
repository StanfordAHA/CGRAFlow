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
parser.add_argument("--smt-switch", help="smt-switch branch", default="master")
parser.add_argument("--cgra-generator", help="generator branch", default="master")
parser.add_argument("--test-bench-generator", help="TestBenchGenerator branch", default="master")

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
    url = "https://github.com/jeffsetter/Halide_CoreIR.git"
    def install(self):
        pass

    @property
    def branch(self):
        return args.halide

class coreir(Repo):
    url = "https://github.com/rdaly525/coreir.git"
    def install(self):
        run("make clean")
        run("sudo make -j 2 install")

    @property
    def branch(self):
        return args.coreir

class pycoreir(Repo):
    url = "https://github.com/leonardt/pycoreir.git"
    def install(self):
        run("pip install -e .")

    @property
    def branch(self):
        return args.coreir

class CGRAMapper(Repo):
    url = "https://github.com/StanfordAHA/CGRAMapper.git"
    def install(self):
        run("make clean")
        run("sudo make -j 2 install")

    @property
    def branch(self):
        return args.mapper

class smt_pnr(Repo):
    url = "https://github.com/cdonovick/smt-pnr"
    @property
    def directory(self):
        return "smt-pnr"

    def install(self):
        run("pip install -e package")

    @property
    def branch(self):
        return args.pnr_doctor

class smt(Repo):
    url = "https://github.com/makaimann/smt-switch"
    @property
    def directory(self):
        return "smt-switch"

    def install(self):
        pass

    @property
    def branch(self):
        return args.smt_switch

class CGRAGenerator(Repo):
    url = "https://github.com/StanfordAHA/CGRAGenerator.git"
    @property
    def branch(self):
        return args.cgra_generator

    def install(self):
        pass

class TestBenchGenerator(Repo):
    url = "https://github.com/StanfordAHA/TestBenchGenerator"
    @property
    def branch(self):
        return args.test_bench_generator

    def install(self):
        pass

repos = (Halide_CoreIR(), coreir(), pycoreir(), CGRAMapper(), smt_pnr(), smt(),
         CGRAGenerator(), TestBenchGenerator())

for repo in repos:
    branch = "master"
    print(type(repo).__name__)
    print("=" * len(type(repo).__name__))
    if not os.path.exists(repo.directory):
        repo.clone()
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
