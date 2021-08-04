permission_cmd () {
  case $1 in
    Linux) echo "stat --printf '%a'" ;;
    Darwin|FreeBSD) echo "stat -f '%Lp'" ;;
    *) return 1 ;;
  esac
}

permission_cmd_dir () {
  case $1 in
    Linux) echo "stat --printf '%U\\n%G\\n%a'" ;;
    Darwin|FreeBSD) echo "stat -f '%Su%n%Sg%n%Lp'" ;;
    *) return 1 ;;
  esac
}