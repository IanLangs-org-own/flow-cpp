#include <flow/types>

#include <flow/fs>
#include <flow/io>
int main()  {
	flow::File* f = nullptr;

	flow::Defer fDEFER = flow::Defer([&](){delete f;});
	
	flow::str Fname = flow::input("introduce archivo: ");
	
	flow::str Fcont = flow::input("introduce nueva linea: ");

	f = new flow::File(Fname);

	f->append(Fcont.ends_with('\n') ? Fcont : Fcont + "\n");

	return 0;
}
