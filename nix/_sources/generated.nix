# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl }:
{
  dynaconf = {
    pname = "dynaconf";
    version = "3.1.4";
    src = fetchurl {
      sha256 = "1fc14whngvcknr49gfqxvkah78bnpaibhramjb2hky2j63c75x5j";
      url = "https://pypi.io/packages/source/d/dynaconf/dynaconf-3.1.4.tar.gz";
    };

  };
  stix2 = {
    pname = "stix2";
    version = "2.1.0";
    src = fetchurl {
      sha256 = "0f698l7iidk4xic4q22vyr66z3wiwj1vhwgyfr714hswkxcwzj8m";
      url = "https://pypi.io/packages/source/s/stix2/stix2-2.1.0.tar.gz";
    };

  };
  stix2-patterns = {
    pname = "stix2-patterns";
    version = "1.3.2";
    src = fetchurl {
      sha256 = "194yi2f59q7vzap0i3lzbaj9wahkaivribrka0h26cic5lqfakqp";
      url = "https://pypi.io/packages/source/s/stix2-patterns/stix2-patterns-1.3.2.tar.gz";
    };

  };
  threatbus-master = {
    pname = "threatbus-master";
    version = "b3839b4d08a349ab4fb45547c6674134a0b03ddc";
    src = fetchgit {
      url = "https://github.com/tenzir/threatbus";
      rev = "b3839b4d08a349ab4fb45547c6674134a0b03ddc";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1rivh7qx7bkj7505pxmn5fa79lwv5n5rs4wf92qcf8jgc7d3igzc";
    };

  };
  threatbus-release = {
    pname = "threatbus-release";
    version = "2021.06.24";
    src = fetchgit {
      url = "https://github.com/tenzir/threatbus";
      rev = "2021.06.24";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "1mcdaffvh23frq59a6rp8k2yi8f92ipsn963g0x6igl9h15mmpvk";
    };

  };
}