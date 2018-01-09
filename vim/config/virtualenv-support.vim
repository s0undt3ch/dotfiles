" Add the virtualenv's site-packages to vim path
if has('python')
  py << EOF
import os
import os.path
import sys
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    sys.path.insert(0, project_base_dir)
    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
    if os.path.exists(activate_this):
        execfile(activate_this, dict(__file__=activate_this))
    else:
       old_os_path = os.environ['PATH']
       os.environ['PATH'] = project_base_dir + os.pathsep + old_os_path
       if sys.platform == 'win32':
           site_packages = os.path.join(project_base_dir, 'Lib', 'site-packages')
       else:
           site_packages = os.path.join(project_base_dir, 'lib', 'python%s' % sys.version[:3], 'site-packages')
       prev_sys_path = list(sys.path)
       import site
       site.addsitedir(site_packages)
       sys.real_prefix = sys.prefix
       sys.prefix = project_base_dir
       # Move the added items to the front of the path:
       new_sys_path = []
       for item in list(sys.path):
           if item not in prev_sys_path:
               new_sys_path.append(item)
               sys.path.remove(item)
       sys.path[:0] = new_sys_path
EOF
  endif
  if has('python3')
  py3 << EOF
import os
import os.path
import sys
import vim
if 'VIRTUAL_ENV' in os.environ:
    project_base_dir = os.environ['VIRTUAL_ENV']
    sys.path.insert(0, project_base_dir)
    activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
    if os.path.exists(activate_this):
        with open(activate_this) as rfh:
          code = compile(rfh.read(), activate_this, 'exec')
          exec(code, dict(__file__=activate_this))
    else:
       old_os_path = os.environ['PATH']
       os.environ['PATH'] = project_base_dir + os.pathsep + old_os_path
       if sys.platform == 'win32':
           site_packages = os.path.join(project_base_dir, 'Lib', 'site-packages')
       else:
           site_packages = os.path.join(project_base_dir, 'lib', 'python%s' % sys.version[:3], 'site-packages')
       prev_sys_path = list(sys.path)
       import site
       site.addsitedir(site_packages)
       sys.real_prefix = sys.prefix
       sys.prefix = project_base_dir
       # Move the added items to the front of the path:
       new_sys_path = []
       for item in list(sys.path):
           if item not in prev_sys_path:
               new_sys_path.append(item)
               sys.path.remove(item)
       sys.path[:0] = new_sys_path
EOF
endif
