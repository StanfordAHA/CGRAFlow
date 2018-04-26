import argparse
import os 
import delegator

tab = "    "
def run(command, *args, cwd=".", **kwargs):
    print(tab + "./" + cwd)
    print(tab + "+ " + command)
    result = delegator.run(command, *args, cwd=cwd, **kwargs)
    print((tab * 2) + (tab * 2).join(result.out.splitlines()))
    if result.return_code:
        print((tab * 2) + (tab * 2).join(result.err.splitlines()))
        raise RuntimeError("Running command {} failed".format(command))
    return result.out

parser = argparse.ArgumentParser(description="Checkout and update branches in project repos")

parser.add_argument("-f", "--force", action="store_true", help="Force rebuild and install", default=False)
parser.add_argument("--with-ssh", action="store_true", help="Clone with ssh", default=False)
parser.add_argument("--coreir", help="coreir branch", default="master")
parser.add_argument("--coreir-remote", help="coreir remote ", default="github.com/rdaly525/coreir.git")
parser.add_argument("--pycoreir", help="pycoreir branch", default="master")
parser.add_argument("--pycoreir-remote", help="pycoreir remote ", default="github.com/leonardt/pycoreir.git")
parser.add_argument("--mapper", help="mapper branch", default="master")
parser.add_argument("--mapper-remote", help="mapper remote", default="github.com/StanfordAHA/CGRAMapper.git")
parser.add_argument("--halide", help="halide branch", default="master")
parser.add_argument("--halide-remote", help="halide remote", default="github.com/jeffsetter/Halide_CoreIR.git")
parser.add_argument("--pnr-doctor", help="pnr branch", default="master")
parser.add_argument("--pnr-doctor-remote", help="pnr remote", default="github.com/cdonovick/smt-pnr.git")
parser.add_argument("--smt-switch", help="smt-switch branch", default="master")
parser.add_argument("--smt-switch-remote", help="smt-switch remote", default="github.com/makaimann/smt-switch.git")
parser.add_argument("--cgra-generator", help="generator branch", default="master")
parser.add_argument("--cgra-generator-remote", help="generator remote", default="github.com/StanfordAHA/CGRAGenerator.git")
parser.add_argument("--test-bench-generator", help="TestBenchGenerator branch", default="master")
parser.add_argument("--test-bench-generator-remote", help="TestBenchGenerator remote", default="github.com/StanfordAHA/TestBenchGenerator.git")

args = parser.parse_args()

class Repo:
    remote_prefix = "git@" if args.with_ssh else "https://"
    def __init__(self, remote, branch):
        """
        Each repository is initialized with a remote and a branch
        """
        self.remote = remote
        self.branch = branch

    def install(self):
        """
        Each repository must implement an `install` method that builds and
        installs the software
        """
        raise NotImplementedError()

    @property
    def directory(self):
        """
        Dynamically returns the directory into which the repository is cloned
        based on the name of the class.  A repository should override this
        property if the directory name does not match with the class name (e.g.
        smt-switch since the dash is not a valid character for a  Python
        identifier)
        """
        return type(self).__name__

    def clone(self):
        """
        Clones the repository using the remote prefix specified by
        args.with_ssh
        """
        run("git clone {}{}".format(Repo.remote_prefix, self.remote))


class Halide_CoreIR(Repo):
    def install(self):
        pass

class coreir(Repo):
    def install(self):
        run("make clean", cwd=repo.directory)
        run("sudo make -j 2 install", cwd=repo.directory)

class pycoreir(Repo):
    def install(self):
        run("pip install -e .", cwd=repo.directory)

class CGRAMapper(Repo):
    def install(self):
        run("make clean", cwd=repo.directory)
        run("sudo make -j 2 install", cwd=repo.directory)

class PnRDoctor(Repo):
    directory = "smt-pnr"

    def install(self):
        run("pip install -e package", cwd=repo.directory)

class smt_switch(Repo):
    directory = "smt-switch"

    def install(self):
        pass

class CGRAGenerator(Repo):
    def install(self):
        pass

class TestBenchGenerator(Repo):
    def install(self):
        pass

repos = (
    Halide_CoreIR(
        remote=args.halide_remote, 
        branch=args.halide
    ), 
    coreir(
        remote=args.coreir_remote, 
        branch=args.coreir
    ), 
    pycoreir(
        remote=args.pycoreir_remote, 
        branch=args.pycoreir
    ), 
    CGRAMapper(
        remote=args.mapper_remote, 
        branch=args.mapper
    ), 
    PnRDoctor(
        remote=args.pnr_doctor_remote, 
        branch=args.pnr_doctor
    ), 
    smt_switch(
        remote=args.smt_switch_remote, 
        branch=args.smt_switch
    ),
    CGRAGenerator(
        remote=args.cgra_generator_remote, 
        branch=args.cgra_generator
    ), 
    TestBenchGenerator(
        remote=args.test_bench_generator_remote, 
        branch=args.test_bench_generator)
)

for repo in repos:
    branch = "master"
    print(type(repo).__name__)
    print("=" * len(type(repo).__name__))
    if not os.path.exists(repo.directory):
        repo.clone()
    current_head = run("git symbolic-ref HEAD", cwd=repo.directory).rstrip()
    if current_head != "refs/heads/{}".format(repo.branch) or args.force:
        run("git fetch origin", cwd=repo.directory)
        run("git checkout {}".format(repo.branch), cwd=repo.directory)
        print(tab + "Installing")
        repo.install()
    else:
        print(tab + "Already on requested branch")
    print()
