darwin_install(){
  if hash elixir 2>/dev/null; then
    echo "You have elixir installed"
  else
    echo "Installing elixir ..."
    if hash brew 2>/dev/null; then
      brew update;
      brew install elixir;
    else
      echo "Please install brew and retry. Link: http://brew.sh/"
    fi
  fi

}

linux_install(){
  echo "Installing linux dependencies for elixir";
  echo "wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb;"
  echo "sudo apt-get update;"
  echo "sudo apt-get install esl-erlang"
  echo "sudo apt-get install elixir;"
}

case "$OSTYPE" in
  darwin*)  darwin_install ;;
  linux*)   linux_install ;;
  *)        echo "unknown: $OSTYPE" ;;
esac
